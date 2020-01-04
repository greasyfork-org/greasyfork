class AddOriginatingScriptIdToBlockedScriptCodes < ActiveRecord::Migration[6.0]
  def change
    add_column :blocked_script_codes, :originating_script_id, :integer
    add_foreign_key :blocked_script_codes, :scripts, column: :originating_script_id, on_delete: :cascade
  end
end
