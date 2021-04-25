class AddSyncFailureCount < ActiveRecord::Migration[6.1]
  def change
    add_column :scripts, :sync_attempt_count, :integer, default: 0, null: false
  end
end
