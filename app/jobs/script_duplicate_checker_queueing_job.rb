class ScriptDuplicateCheckerQueueingJob < ApplicationJob
  queue_as :low
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform
    Script
      .not_deleted
      .left_joins(:script_similarities)
      .group('scripts.id')
      .order('min(script_similarities.checked_at)', :id)
      .limit(5)
      .pluck('scripts.id')
      .reject { |id| ScriptDuplicateCheckerJob.currently_queued_script_ids.include?(id) }
      .each { |id| ScriptDuplicateCheckerJob.perform_later(id) }
  end
end
