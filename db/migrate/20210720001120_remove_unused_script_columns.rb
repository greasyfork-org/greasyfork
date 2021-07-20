class RemoveUnusedScriptColumns < ActiveRecord::Migration[6.1]
  def change
    remove_columns(:scripts, :script_sync_source_id, :script_delete_type_id)
  end
end
