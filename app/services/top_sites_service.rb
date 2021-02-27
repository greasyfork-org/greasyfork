class TopSitesService
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
                          "AND s.id IN (#{([0] + LocalizedScriptAttribute.where(locale_id: locale_id).distinct.pluck(:script_id)).join(',')})"
                        else
                          ''
                        end
        user_clause = ("AND s.id IN (#{([0] + User.find(user_id).script_ids).join(',')})" if user_id)
        sql = <<~SQL.squish
          SELECT
            text, SUM(daily_installs) install_count, COUNT(s.id) script_count
          FROM script_applies_tos
          JOIN scripts s ON script_id = s.id
          JOIN site_applications on site_applications.id = site_application_id
          WHERE
            domain
            AND blocked = 0
            AND script_type_id = 1
            AND script_delete_type_id IS NULL
            AND !tld_extra
            #{subset_clause}
            #{locale_clause}
            #{user_clause}
          GROUP BY text
          ORDER BY text
        SQL
        Rails.logger.warn('Loading by_sites') if Greasyfork::Application.config.log_cache_misses
        by_sites = Script.connection.select_rows(sql)
        all_sites = all_sites_count.values.to_a
        Rails.logger.warn('Combining by_sites and all_sites') if Greasyfork::Application.config.log_cache_misses
        # combine with "All sites" number
        a = ([[nil] + all_sites] + by_sites)
        a.map { |key, install_count, script_count| [key, { installs: install_count.to_i, scripts: script_count.to_i }] }.to_h
      end
    end

    def get_top_by_sites(script_subset:, locale_id: nil, user_id: nil)
      return ApplicationController.cache_with_log("scripts/get_top_by_sites/#{script_subset}/#{locale_id}/#{user_id}") do
        get_by_sites(script_subset: script_subset, locale_id: locale_id, user_id: user_id).sort { |a, b| b[1][:installs] <=> a[1][:installs] }.first(10)
      end
    end

    def all_sites_count
      return ApplicationController.cache_with_log('all_sites_count', expires_in: 10.minutes) do
        sql = <<-SQL.squish
        SELECT
          sum(daily_installs) install_count, count(distinct scripts.id) script_count
        FROM scripts
        WHERE
          script_type_id = 1
          AND script_delete_type_id is null
          AND NOT EXISTS (SELECT * FROM script_applies_tos WHERE script_id = scripts.id)
        SQL
        Script.connection.select_all(sql).first
      end
    end
  end
end
