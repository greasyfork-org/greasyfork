class BackgroundJob < ApplicationJob
  queue_as :background
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform
    ScriptSyncQueueingJob.perform_later
    ScriptDuplicateCheckerQueueingJob.perform_later
  end
end
