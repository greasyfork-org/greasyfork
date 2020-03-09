require 'sidekiq-scheduler'

class SyncScriptsJob
  include Sidekiq::Worker

  sidekiq_options queue: 'low'

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
  end
end