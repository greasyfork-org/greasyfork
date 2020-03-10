class BackgroundJob < ApplicationJob
  queue_as :background
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform
    [ScriptSyncQueueingJob, ScriptDuplicateCheckerQueueingJob].reject(&:enqueued?).each(&:perform_later)
    BackgroundJob.perform_later
  end
end
