class InactiveUserNotificationJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  USER_LIMIT = 100

  def perform
    User.inactive_notifiable.limit(USER_LIMIT).each(&:send_inactive_notification_email!)
  end
end
