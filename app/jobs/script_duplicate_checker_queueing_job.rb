class ScriptDuplicateCheckerQueueingJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log

  def perform
    number_to_enqueue = ScriptDuplicateCheckerJob.spare_processes

    script_ids = Rails.cache.fetch('ScriptDuplicateCheckerQueueingJob.queue') { [] }
    Rails.logger.warn("Cached script IDs are: #{script_ids}")

    script_ids = calculate_script_ids if script_ids.empty?

    script_ids.shift(number_to_enqueue)
              .each { |id| ScriptDuplicateCheckerJob.perform_async(id) }

    Rails.logger.warn("Caching script IDs: #{script_ids}")
    Rails.cache.write('ScriptDuplicateCheckerQueueingJob.queue', script_ids)
  end

  def calculate_script_ids
    Script
      .left_joins(:script_similarities)
      .group('scripts.id')
      .order('min(script_similarities.checked_at)', :deleted_at, :id)
      .limit(10)
      .pluck('scripts.id')
  end
end
