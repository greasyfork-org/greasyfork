class MigrateUserNotifyAsReported < ActiveRecord::Migration[7.2]
  def change
    User.where(notify_as_reported: false).find_each do |user|
      UserNotificationSetting.update_delivery_types_for_user(user, Notification::NOTIFICATION_TYPE_REPORT_FILED_REPORTED, [])
      UserNotificationSetting.update_delivery_types_for_user(user, Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTED, [])
    end
  end
end
