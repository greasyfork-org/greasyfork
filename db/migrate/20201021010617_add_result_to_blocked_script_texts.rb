class AddResultToBlockedScriptTexts < ActiveRecord::Migration[6.0]
  def change
    add_column :blocked_script_texts, :result, :string, limit: 10
    execute 'UPDATE blocked_script_texts SET result = "review" WHERE result IS NULL'
    change_column_null :blocked_script_texts, :result, false
  end
end
