class ScriptDuplicateCheckerQueueingJob < ApplicationJob
  queue_as :low

  def perform
    number_to_enqueue = ScriptDuplicateCheckerJob::DESIRED_RUN_COUNT - ScriptDuplicateCheckerJob.currently_queued_script_ids.count
    Rails.logger.warn("We should enqueue #{number_to_enqueue} jobs.")
    return if number_to_enqueue <= 0

    script_ids = Rails.cache.fetch('ScriptDuplicateCheckerQueueingJob.queue') { [] }
    Rails.logger.warn("Cached script IDs are: #{script_ids}")

    script_ids = calculate_script_ids if script_ids.empty?

    script_ids.shift(number_to_enqueue)
              .reject { |id| ScriptDuplicateCheckerJob.currently_queued_script_ids.include?(id) }
              .each { |id| ScriptDuplicateCheckerJob.perform_later(id) }

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
