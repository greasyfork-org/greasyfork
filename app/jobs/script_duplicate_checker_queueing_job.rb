class ScriptDuplicateCheckerQueueingJob < ApplicationJob
  queue_as :background
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform
    currently_running = Sidekiq::Queue.new('low')
                            .select { |sq| sq.item['wrapped'] == 'ScriptDuplicateCheckerJob' }
                            .map{|job| job.args.first['arguments'].first }
    Script
        .not_deleted
        .left_joins(:script_similarities)
        .group('scripts.id')
        .order('min(script_similarities.checked_at)', :id)
        .limit(5)
        .pluck('scripts.id')
        .reject { |id| currently_running.include?(id) }
        .each { |id| ScriptDuplicateCheckerJob.perform_later(id) }
    self.class.perform_later
  end
end
