class ScriptSyncQueueingJob < ApplicationJob
  queue_as :background
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform
    Script
        .where(script_sync_type_id: 2)
        .where('last_attempted_sync_date < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY)')
        .order(:last_attempted_sync_date)
        .limit(100)
        .find_each(batch_size: 10) do |script|
      ScriptSyncJob.perform_later(script.id)
    end
    self.class.perform_later
  end
end
