class ScriptSyncQueueingJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  def perform
    Script
      .where(sync_type: 'automatic')
      .where('last_attempted_sync_date < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 12 HOUR)')
      .order(:last_attempted_sync_date)
      .limit(1000)
      .each do |script|
        ScriptSyncJob.perform_later(script.id)
    end
  end
end
