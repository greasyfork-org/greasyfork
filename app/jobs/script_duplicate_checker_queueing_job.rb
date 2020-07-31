class ScriptDuplicateCheckerQueueingJob < ApplicationJob
  queue_as :low

  def perform
    to_enqueue = ScriptDuplicateCheckerJob::QUEUE_LIMIT - ScriptDuplicateCheckerJob.currently_queued_script_ids.count
    return unless to_enqueue > 0

    Script
      .not_deleted
      .left_joins(:script_similarities)
      .group('scripts.id')
      .order('min(script_similarities.checked_at)', :id)
      .limit(to_enqueue)
      .pluck('scripts.id')
      .reject { |id| ScriptDuplicateCheckerJob.currently_queued_script_ids.include?(id) }
      .each_with_index do |id, i|
      # Don't start them at the exact same time so that ScriptDuplicateCheckerJob can check the execution limit
      # properly.
      ScriptDuplicateCheckerJob.set(wait: i.seconds).perform_later(id)
    end
  end
end
