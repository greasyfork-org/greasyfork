namespace :script_stats do
  desc 'refresh'
  task refresh: :environment do
    TopSitesService.refresh!
  end
end
