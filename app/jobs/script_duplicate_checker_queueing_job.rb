require 'sidekiq-scheduler'

class ScriptDuplicateCheckerQueueingJob
  include Sidekiq::Worker

  def perform
    Script
        .not_deleted
        .left_joins(:script_similarities)
        .group('scripts.id')
        .order('min(script_similarities.checked_at)', :id)
        .limit(5)
        .pluck('scripts.id')
        .each { |id| ScriptDuplicateCheckerJob.perform_later(id) }
  end
end
