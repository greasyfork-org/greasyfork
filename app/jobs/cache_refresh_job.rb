class CacheRefreshJob < ApplicationJob
  queue_as :low

  def perform
    ScriptsController.get_by_sites({ force: true })
    self.class.set(wait: 1.hour).perform_later
  end
end
