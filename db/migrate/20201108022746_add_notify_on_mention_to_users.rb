class AddNotifyOnMentionToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :notify_on_mention, :boolean, default: false, null: false
  end
end
