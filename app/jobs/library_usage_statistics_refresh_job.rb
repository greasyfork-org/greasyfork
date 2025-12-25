class LibraryUsageStatisticsRefreshJob
  include Sidekiq::Job

  sidekiq_options queue: 'background'

  def perform
    LibraryUsageStatistics.refresh_usages
  end
end
