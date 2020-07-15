class AddConversationStats < ActiveRecord::Migration[6.0]
  def change
    add_column :conversations, :stat_last_message_date, :datetime
    add_column :conversations, :stat_last_poster_id, :integer
  end
end
