class ScriptDuplicateCheckerQueueingJob < ApplicationJob
  queue_as :low

  def perform
    # Sleep a bit so maybe we can notice the throttle limit?
    sleep rand()

    if self.class.throttled_limit_reached?
      self.class.set(wait: 5.seconds).perform_later
      return
    end

    Script
      .not_deleted
      .left_joins(:script_similarities)
      .group('scripts.id')
      .order('min(script_similarities.checked_at)', :id)
      .limit(5)
      .pluck('scripts.id')
      .reject { |id| ScriptDuplicateCheckerJob.currently_queued_script_ids.include?(id) }
      .each_with_index do |id, i|
      # Don't start them at the exact same time so that ScriptDuplicateCheckerJob can check the execution limit
      # properly.
      ScriptDuplicateCheckerJob.set(wait: i.seconds).perform_later(id)
    end
  end
end
