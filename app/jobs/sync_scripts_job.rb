class SyncScriptsJob < ApplicationJob
  queue_as :low
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform
    Script
        .where(script_sync_type_id: 2)
        .where('last_attempted_sync_date < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY)')
        .order(:last_attempted_sync_date)
        .limit(100)
        .find_each(batch_size: 10) do |script|
      begin
        result = ScriptImporter::ScriptSyncer.sync(script)
      rescue => ex
        #puts "#{script.id} exception - #{ex}"
      end
    end
    self.class.perform_later(wait: 5.minutes)
  end
end
