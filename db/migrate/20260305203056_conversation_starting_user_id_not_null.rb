class ConversationStartingUserIdNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :conversations, :starting_user_id, false
  end
end
