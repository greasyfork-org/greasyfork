class DropScriptDeleteTypes < ActiveRecord::Migration[7.2]
  def change
    drop_table :script_delete_types
  end
end
