class AddStatsToDiscussions < ActiveRecord::Migration[6.0]
  def change
    add_column :discussions, :stat_reply_count, :integer, default: 0, null: false
    add_column :discussions, :stat_last_reply_date, :datetime
    add_column :discussions, :stat_last_replier_id, :integer
    Discussion.all.each(&:update_stats!)
  end
end
