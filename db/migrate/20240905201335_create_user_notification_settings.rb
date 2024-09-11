class CreateUserNotificationSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :user_notification_settings do |t|
      t.references :user, null: false, index: false
      t.integer :notification_type, null: false
      t.integer :delivery_type, null: false
      t.boolean :enabled, null: false
      t.index [:user_id, :notification_type]
    end
  end
end
