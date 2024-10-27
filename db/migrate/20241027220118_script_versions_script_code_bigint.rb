class ScriptVersionsScriptCodeBigint < ActiveRecord::Migration[7.2]
  def change
    change_table :script_versions do |t|
      t.change :script_code_id, :bigint
      t.change :rewritten_script_code_id, :bigint
    end

    add_foreign_key :script_versions, :script_codes
    add_foreign_key :script_versions, :script_codes, column: :rewritten_script_code_id
  end
end
