class RenameScriptSyncType < ActiveRecord::Migration[7.1]
  def change
    rename_column :scripts, :script_sync_type_id, :sync_type
  end
end
