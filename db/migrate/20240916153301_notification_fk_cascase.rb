class NotificationFkCascase < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :notifications, :users
    add_foreign_key :notifications, :users, on_delete: :cascade
    add_foreign_key :user_notification_settings, :users, on_delete: :cascade
  end
end
