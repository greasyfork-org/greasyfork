class MigrateUserNotifyAsReporter < ActiveRecord::Migration[7.2]
  def change
    User.where(notify_as_reporter: false).find_each do |user|
      UserNotificationSetting.update_delivery_types_for_user(user, Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTER, [])
    end
  end
end
