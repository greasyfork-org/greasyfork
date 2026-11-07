class RemoveUpdateCheckCountsScriptForeignKey < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :update_check_counts, :scripts
  end

  def down
    execute 'DELETE FROM update_check_counts WHERE script_id NOT IN (SELECT id FROM scripts)'
    add_foreign_key :update_check_counts, :scripts, on_delete: :cascade
  end
end
