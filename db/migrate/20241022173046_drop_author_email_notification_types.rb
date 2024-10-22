class DropAuthorEmailNotificationTypes < ActiveRecord::Migration[7.2]
  def change
    drop_table :author_email_notification_types
  end
end
