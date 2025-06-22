class ScriptDuplicateCheckerQueueingJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  def perform
    number_to_enqueue = ScriptDuplicateCheckerJob.spare_processes
    if number_to_enqueue <= 0
      Rails.logger.info("Should enqueue #{number_to_enqueue}, skipping.")
      return
    end

    script_ids = Rails.cache.fetch('ScriptDuplicateCheckerQueueingJob.queue') { [] }
    Rails.logger.warn("Cached script IDs are: #{script_ids}")

    script_ids = calculate_script_ids if script_ids.empty?

    script_ids_to_enqueue = script_ids.shift(number_to_enqueue)
    script_ids_to_enqueue.each { |id| ScriptDuplicateCheckerJob.perform_async(id) }

    # Set it up for the next run if we've run out. That way, it can immediately enqueue some jobs when it runs rather
    # than having to wait for the query again.
    script_ids = calculate_script_ids - script_ids_to_enqueue if script_ids.empty?

    Rails.logger.warn("Caching script IDs: #{script_ids}")
    Rails.cache.write('ScriptDuplicateCheckerQueueingJob.queue', script_ids)
  end

  def calculate_script_ids
    Script
      .left_joins(:script_similarities)
      .group('scripts.id')
      .order('min(script_similarities.checked_at)', :deleted_at, :id)
      .limit(50)
      .pluck('scripts.id')
  end
end
