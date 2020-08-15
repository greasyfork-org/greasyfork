class AddConversationNotificationSettings < ActiveRecord::Migration[6.0]
  def change
    change_table :users do |t|
      t.column :subscribe_on_conversation_starter, :boolean, default: true, null: false
      t.column :subscribe_on_conversation_receiver, :boolean, default: true, null: false
    end
  end
end
