class ScriptDeletedAtBackfill < ActiveRecord::Migration[6.0]
  def up
    execute 'update scripts set deleted_at = updated_at where script_delete_type_id IS NOT NULL'
  end
end
