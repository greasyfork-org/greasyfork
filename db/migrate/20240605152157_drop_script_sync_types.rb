class DropScriptSyncTypes < ActiveRecord::Migration[7.1]
  def change
    drop_table :script_sync_types
  end
end
