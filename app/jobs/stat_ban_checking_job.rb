require 'google_analytics'

class StatBanCheckingJob
  include Sidekiq::Job

  MIN_DISCREPANCY_MULTIPLIER = 5
  MIN_INSTALL_COUNT = 100
  DAYS_AGO_TO_CHECK = [2, 3, 4].freeze

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  def perform
    script_ids = nil
    DAYS_AGO_TO_CHECK.each do |days_ago|
      script_ids = find_discrepancies(days_ago.days.ago.to_date, limit_to_script_ids: script_ids)
    end
    Rails.logger.info("Found discrepancies for #{script_ids}")

    already_actively_banned_script_ids = StatBan.active.where(script_id: script_ids).pluck(:script_id)
    Rails.logger.info("Already banned script IDs: #{already_actively_banned_script_ids}")
    script_ids -= already_actively_banned_script_ids

    script_ids.each { |script_id| StatBan.add_next_ban!(script_id) }
  end

  def find_discrepancies(date, limit_to_script_ids: nil)
    install_data = combined_install_data(date, limit_to_script_ids:)
    install_data.select { |_script_id, _gf_installs, _ga_installs, ratio| ratio && ratio > MIN_DISCREPANCY_MULTIPLIER }.map(&:first)
  end

  def combined_install_data(date, limit_to_script_ids: nil)
    return [] if limit_to_script_ids == []

    gf_install_data = Script.connection.select_rows("select script_id, installs from install_counts where install_date = '#{date}' AND installs > #{MIN_INSTALL_COUNT} #{"AND script_id IN (#{limit_to_script_ids.join(',')})" if limit_to_script_ids} group by script_id order by installs").to_h
    ga_stats = ga_install_data(date)

    gf_install_data.map { |script_id, installs| [script_id, installs, ga_stats[script_id], ga_stats[script_id] ? installs / ga_stats[script_id] : nil] }
  end

  def ga_install_data(date)
    gf_install_data = GoogleAnalytics.report_installs(date)
    sf_install_data = GoogleAnalytics.report_installs(date, site: :sleazyfork)
    gf_install_data.merge(sf_install_data) { |_key, gf_v, sf_v| gf_v + sf_v }
  end
end
