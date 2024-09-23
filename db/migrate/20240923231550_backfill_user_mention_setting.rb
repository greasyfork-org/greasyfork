class BackfillUserMentionSetting < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    User.where(notify_on_mention: true).find_each do |user|
      UserNotificationSetting.update_delivery_types_for_user(user, Notification::NOTIFICATION_TYPE_MENTION, [UserNotificationSetting::DELIVERY_TYPE_ON_SITE, UserNotificationSetting::DELIVERY_TYPE_EMAIL])
    end
  end
end
