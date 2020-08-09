class AddMoreNotificationSettings < ActiveRecord::Migration[6.0]
  def change
    change_table :users do |t|
      t.column :subscribe_on_discussion, :boolean, default: true, null: false
      t.column :subscribe_on_comment, :boolean, default: true, null: false
    end
  end
end
