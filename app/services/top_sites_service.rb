class TopSitesService
  SCRIPT_SUBSETS = [:greasyfork, :sleazyfork, :all].freeze

  class << self
    # Returns a hash, key: site name, value: hash with keys installs, scripts
    def get_by_sites(script_subset:, locale_id: nil, user_id: nil, **cache_options)
      return ApplicationController.cache_with_log("scripts/get_by_sites/#{script_subset}/#{locale_id}/#{user_id}", cache_options) do
        subset_clause = case script_subset
                        when :greasyfork
                          'AND `sensitive` = false'
                        when :sleazyfork
                          'AND `sensitive` = true'
                        else
                          ''
                        end
        locale_clause = if locale_id
                          "AND s.id IN (#{([0] + LocalizedScriptAttribute.where(locale_id:).distinct.pluck(:script_id)).join(',')})"
                        else
                          ''
                        end
        user_clause = ("AND s.id IN (#{([0] + User.find(user_id).script_ids).join(',')})" if user_id)
        sql = <<~SQL.squish
          SELECT
            domain_text, SUM(daily_installs) install_count, COUNT(s.id) script_count
          FROM script_applies_tos
          JOIN scripts s ON script_id = s.id
          JOIN site_applications on site_applications.id = site_application_id
          WHERE
            domain_text IS NOT NULL
            AND blocked = 0
            AND script_type = 1
            AND delete_type IS NULL
            AND !tld_extra
            #{subset_clause}
            #{locale_clause}
            #{user_clause}
          GROUP BY domain_text
          ORDER BY domain_text
        SQL
        Rails.logger.warn('Loading by_sites') if Greasyfork::Application.config.log_cache_misses
        by_sites = Script.connection.select_rows(sql)
        all_sites = all_sites_count.values.to_a
        Rails.logger.warn('Combining by_sites and all_sites') if Greasyfork::Application.config.log_cache_misses
        # combine with "All sites" number
        a = ([[nil] + all_sites] + by_sites)
        rv = a.to_h { |key, install_count, script_count| [key, { installs: install_count.to_i, scripts: script_count.to_i }] }

        # We also write a cache key for each individual site as just reading the the full list from redis takes ~50ms,
        # and we want to avoid that for scripts/show.
        Rails.cache.write_multi(rv.to_h { |site, stats| [site_script_count_cache_key(site:, script_subset:), stats[:scripts]] }) if locale_id.nil? && user_id.nil?

        rv
      end
    end

    def get_top_by_sites(script_subset:, locale_id: nil, user_id: nil)
      return ApplicationController.cache_with_log("scripts/get_top_by_sites/#{script_subset}/#{locale_id}/#{user_id}") do
        get_by_sites(script_subset:, locale_id:, user_id:).sort { |a, b| b[1][:installs] <=> a[1][:installs] }.first(10)
      end
    end

    def all_sites_count
      return ApplicationController.cache_with_log('all_sites_count', expires_in: 10.minutes) do
        sql = <<-SQL.squish
        SELECT
          sum(daily_installs) install_count, count(distinct scripts.id) script_count
        FROM scripts
        WHERE
          script_type = 1
          AND delete_type is null
          AND NOT EXISTS (SELECT * FROM script_applies_tos WHERE script_id = scripts.id)
        SQL
        Script.connection.select_all(sql).first
      end
    end

    # Returns a Hash of site name to script count.
    def script_counts_for_sites(sites:, script_subset:)
      values = Rails.cache.read_multi(*sites.map { |site| site_script_count_cache_key(site:, script_subset:) })
      sites.index_with { |site| values[site_script_count_cache_key(site:, script_subset:)] || 0 }
    end

    def site_script_count_cache_key(site:, script_subset:)
      "site_script_count/#{script_subset}/#{site}"
    end

    def refresh!
      (Locale.ui_available.pluck(:id) + [nil]).each do |locale_id|
        SCRIPT_SUBSETS.each do |script_subset|
          TopSitesService.get_by_sites(script_subset:, locale_id:, force: true)
        end
      end
    end
  end
end
