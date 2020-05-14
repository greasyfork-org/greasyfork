class AddIndexToLastReplyDate < ActiveRecord::Migration[6.0]
  def change
    add_index :discussions, :stat_last_reply_date
  end
end
