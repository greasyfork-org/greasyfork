class AddUserInactiveNotificationSentAt < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :inactive_notification_sent_at, :datetime
  end
end
