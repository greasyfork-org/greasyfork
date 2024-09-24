class DeleteOldNotificationsJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 15.minutes.to_i

  def perform
    Notification.where(created_at: ..1.year.ago).delete_all
  end
end
