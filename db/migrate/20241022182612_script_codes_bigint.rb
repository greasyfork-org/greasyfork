class ScriptCodesBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :script_codes, :id, :bigint, auto_increment: true
  end
end
