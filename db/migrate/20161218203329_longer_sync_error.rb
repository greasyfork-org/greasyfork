class LongerSyncError < ActiveRecord::Migration[5.0]
  def change
    change_column :scripts, :sync_error, :string, limit: 1000
  end
end
