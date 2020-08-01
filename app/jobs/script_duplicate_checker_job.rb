require 'zlib'

class ScriptDuplicateCheckerJob < ApplicationJob
  queue_as :low

  def perform(script_id)
    Rails.logger.warn("[#{script_id}] Started")
    Rails.logger.warn("[#{script_id}] Currently enqueued/running: #{self.class.currently_queued_script_ids}")
    Rails.logger.warn("[#{script_id}] Running queued: #{ScriptDuplicateCheckerQueueingJob.enqueued?}")
    Rails.logger.warn("[#{script_id}] Currently running throttled count: #{ScriptDuplicateCheckerJob.currently_running.count + ScriptDuplicateCheckerQueueingJob.currently_running.count}")
    Rails.logger.warn("[#{script_id}] All running jobs (#{Sidekiq::Workers.new.count}): #{Sidekiq::Workers.new.map { |_process_id, _thread_id, work| work['payload'] }}")

    if self.class.throttled_limit_reached?
      self.class.set(wait: 5.seconds).perform_later(script_id)
      return
    end

    now = Time.now

    begin
      script = Script.find(script_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    other_scripts = Script.not_deleted.where.not(id: script_id)

    last_run = ScriptSimilarity.where(script_id: script_id).maximum(:checked_at)
    if last_run && script.code_updated_at < last_run
      # Eliminate the ones we are up to date on
      up_to_date_script_ids = ScriptSimilarity.where(script_id: script_id).joins(:other_script).where(['code_updated_at < ?', last_run]).pluck(:other_script_id)
      other_scripts = other_scripts.where.not(id: up_to_date_script_ids)
    end

    results = CodeSimilarityScorer.get_similarities(script, other_scripts)

    return if results.none?

    ScriptSimilarity.where(script_id: script_id).delete_all
    bulk_data = results.sort_by(&:last).last(100).map { |other_script_id, similarity| { script_id: script_id, other_script_id: other_script_id, similarity: similarity.round(3), checked_at: now } }
    ScriptSimilarity.upsert_all(bulk_data)
  end

  def self.currently_queued_script_ids
    return [] unless Rails.env.production?

    [
      currently_enqueued.map { |job| job.args.first['arguments'].first },
      currently_running.map { |p| p['args'].first['arguments'].first },
      currently_scheduled.map { |p| p['args'].first['arguments'].first },
    ].flatten
  end
end
