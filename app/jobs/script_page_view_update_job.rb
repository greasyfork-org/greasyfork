require 'google_analytics'

class ScriptPageViewUpdateJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  def perform
    views_by_script_id = Hash.new(0)
    GoogleAnalytics.report_pageviews.each do |path, page_views|
      m = %r{.*/scripts/([0-9]+)-.*}.match(path)
      next if m.nil?

      views_by_script_id[m[1].to_i] += page_views
    end

    Script.update_all(page_views: 0)
    views_by_script_id.each do |script_id, page_views|
      Script.where(id: script_id).update_all(page_views:)
    end
  end
end
