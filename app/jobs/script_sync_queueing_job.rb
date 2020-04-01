class ScriptSyncQueueingJob < ApplicationJob
  queue_as :low

  def perform
    Script
      .where(script_sync_type_id: 2)
      .where('last_attempted_sync_date < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 12 HOUR)')
      .order(:last_attempted_sync_date)
      .limit(1000)
      .each do |script|
      ScriptSyncJob.perform_later(script.id)
    end
  end
end
