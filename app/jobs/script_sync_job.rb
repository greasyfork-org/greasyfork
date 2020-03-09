class ScriptSyncJob < ApplicationJob
  queue_as :low
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform(script_id)
    begin
      result = ScriptImporter::ScriptSyncer.sync(Script.find(script_id))
    rescue => ex
      #puts "#{script.id} exception - #{ex}"
    end
  end
end
