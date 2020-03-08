class ScriptCodeHashNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :script_codes, :code_hash, false
  end
end
