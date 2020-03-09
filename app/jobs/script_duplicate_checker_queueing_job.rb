class ScriptDuplicateCheckerQueueingJob < ApplicationJob
  queue_as :low
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform
    currently_running = ScriptDuplicateCheckerJob.currently_queued_script_ids
    Script
        .not_deleted
        .left_joins(:script_similarities)
        .group('scripts.id')
        .order('min(script_similarities.checked_at)', :id)
        .limit(5)
        .pluck('scripts.id')
        .reject { |id| currently_running.include?(id) }
        .each { |id| ScriptDuplicateCheckerJob.perform_later(id) }
  end
end
