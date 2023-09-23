class DropScriptTypes < ActiveRecord::Migration[7.0]
  def change
    drop_table :script_types
    remove_column :scripts, :script_type_id
  end
end
