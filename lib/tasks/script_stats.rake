SCRIPT_STATS_SITES = [:greasyfork, :sleazyfork, :all].freeze

namespace :script_stats do
  desc 'refresh'
  task refresh: :environment do
    (Locale.where(ui_available: true).pluck(:id) + [nil]).each do |locale_id|
      SCRIPT_STATS_SITES.each do |script_subset|
        TopSitesService.get_by_sites(script_subset: script_subset, locale_id: locale_id, force: true)
      end
    end
  end
end
