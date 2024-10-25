class ConversationsUserBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :conversations, :stat_last_poster_id, :bigint
    change_column :conversations_users, :user_id, :bigint
  end
end
