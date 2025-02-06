class ChangeBlockedScriptCodesResult < ActiveRecord::Migration[8.0]
  def change
    add_column :blocked_script_codes, :result, :integer, null: false, default: 0
    execute 'update blocked_script_codes set result = 1 where serious'
    remove_column :blocked_script_codes, :serious
  end
end
