class ScriptSyncJob < ApplicationJob
  queue_as :low
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform(script_id)
    ScriptImporter::ScriptSyncer.sync(Script.find(script_id))
  rescue StandardError
    # puts "#{script.id} exception - #{ex}"
  end
end
