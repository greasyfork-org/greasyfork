class AddCaseInsensitiveToBlockedScriptCodes < ActiveRecord::Migration[7.1]
  def change
    add_column :blocked_script_codes, :case_insensitive, :boolean, null: false, default: false
  end
end
