class AddScriptDeleteTypeToScripts < ActiveRecord::Migration[6.1]
  def change
    add_column :scripts, :delete_type, :integer
    execute 'UPDATE scripts SET delete_type = 2 WHERE script_delete_type_id = 2'
    execute 'UPDATE scripts SET delete_type = 3 WHERE script_delete_type_id = 1 AND replaced_by_script_id IS NOT NULL'
    execute 'UPDATE scripts SET delete_type = 1 WHERE script_delete_type_id = 1 AND replaced_by_script_id IS NULL'
  end
end
