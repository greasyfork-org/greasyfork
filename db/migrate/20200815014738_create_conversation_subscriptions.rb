class CreateConversationSubscriptions < ActiveRecord::Migration[6.0]
  def change
    create_table :conversation_subscriptions do |t|
      t.belongs_to :conversation, null: false, index: false
      t.belongs_to :user, null: false, type: :integer
      t.timestamps
    end
    add_foreign_key :conversation_subscriptions, :conversations, on_delete: :cascade
    add_foreign_key :conversation_subscriptions, :users, on_delete: :cascade
    add_index :conversation_subscriptions, [:conversation_id, :user_id], unique: true
  end
end
