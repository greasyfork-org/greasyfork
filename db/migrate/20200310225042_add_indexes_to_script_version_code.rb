class AddIndexesToScriptVersionCode < ActiveRecord::Migration[6.0]
  def change
    add_index :script_versions, :script_code_id
    add_index :script_versions, :rewritten_script_code_id
  end
end
