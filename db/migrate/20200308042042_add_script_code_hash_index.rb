class AddScriptCodeHashIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :script_codes, :code_hash
  end
end
