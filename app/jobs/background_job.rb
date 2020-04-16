class BackgroundJob < ApplicationJob
  queue_as :background

  def perform
    [ScriptSyncQueueingJob, ScriptDuplicateCheckerQueueingJob].reject(&:enqueued?).each(&:perform_later)
    BackgroundJob.set(wait: 10.seconds).perform_later
  end
end
