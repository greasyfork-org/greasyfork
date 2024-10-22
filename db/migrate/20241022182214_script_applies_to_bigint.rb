class ScriptAppliesToBigint < ActiveRecord::Migration[7.2]
  def change
    change_column  :script_applies_tos, :id, :bigint, auto_increment: true
  end
end
