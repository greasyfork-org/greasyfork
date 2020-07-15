class CreateConversationUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :conversations_users do |t|
      t.bigint :conversation_id, null: false
      t.integer :user_id, null: false
    end
    add_foreign_key :conversations_users, :conversations, on_delete: :cascade
  end
end
