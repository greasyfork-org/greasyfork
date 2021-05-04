class ScriptSyncJob < ApplicationJob
  queue_as :low

  def perform(script_id)
    script = Script.find(script_id)

    # Guard against script parsing crashing the process. If it fails 3 times, punt it for a month.
    if script.sync_attempt_count >= 3
      script.update(last_attempted_sync_date: 1.month.from_now, sync_attempt_count: 0)
      return
    end

    script.update(sync_attempt_count: script.sync_attempt_count + 1)

    ScriptImporter::ScriptSyncer.sync(script)

    script.reload.update(sync_attempt_count: 0)
  rescue StandardError
    # puts "#{script.id} exception - #{ex}"
  end
end
