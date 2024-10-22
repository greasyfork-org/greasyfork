class RemoveUnusedUserColumns < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :author_email_notification_type_id
    remove_column :users, :notify_on_mention
  end
end
