class DropScriptSyncSourceType < ActiveRecord::Migration[6.1]
  def change
    drop_table :script_sync_sources
  end
end
