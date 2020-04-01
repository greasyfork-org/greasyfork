class BackgroundJob < ApplicationJob
  queue_as :background

  def perform
    [ScriptSyncQueueingJob, ScriptDuplicateCheckerQueueingJob].reject(&:enqueued?).each(&:perform_later)
    BackgroundJob.perform_later
  end
end
