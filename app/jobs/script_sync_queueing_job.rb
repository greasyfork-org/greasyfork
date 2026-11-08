class ScriptSyncQueueingJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  RESYNC_INTERVAL_HOURS = 12

  def perform
    # To keep it even throughout the interval, only enqueue up to 2x the average per minute.
    scripts_per_hour = Script.where(sync_type: 'automatic').count / RESYNC_INTERVAL_HOURS
    number_to_enqueue = [scripts_per_hour / 60 * 2, 1].max

    Script
      .where(sync_type: 'automatic')
      .where("last_attempted_sync_date < DATE_SUB(UTC_TIMESTAMP(), INTERVAL #{RESYNC_INTERVAL_HOURS} HOUR)")
      .order(:last_attempted_sync_date)
      .limit(number_to_enqueue)
      .each do |script|
      ScriptSyncJob.perform_later(script.id)
    end
  end
end
