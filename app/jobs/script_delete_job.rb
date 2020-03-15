class ScriptDeleteJob < ApplicationJob
  queue_as :low
  self.queue_adapter = :sidekiq if Rails.env.production?

  def perform
    # Temp disabled - https://github.com/pat/thinking-sphinx/issues/1161
    # Script.where(locked: true).where.not(script_delete_type_id: nil).where(['deleted_at < ?', 1.year.ago]).limit(100).each(&:destroy)
    self.class.set(wait: 1.hour).perform_later
  end
end
