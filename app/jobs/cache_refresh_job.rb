class CacheRefreshJob < ApplicationJob
  queue_as :low

  def perform
    (Locale.where(ui_available: true).pluck(:id) + [nil]).each do |locale_id|
      [:greasyfork, :sleazyfork].each do |script_subset|
        TopSitesService.get_by_sites(script_subset: script_subset, locale_id: locale_id, force: true)
      end
    end
    self.class.set(wait: 1.hour).perform_later
  end
end
