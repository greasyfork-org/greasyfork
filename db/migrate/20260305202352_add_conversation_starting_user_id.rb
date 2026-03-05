class AddConversationStartingUserId < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :starting_user_id, :bigint
    add_index :conversations, :starting_user_id
  end
end
