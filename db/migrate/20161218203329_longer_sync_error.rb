class LongerSyncError < ActiveRecord::Migration[5.0]
  def change
    change_column :scripts, :sync_error, :string, length: 1000
  end
end
