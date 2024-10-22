class ScriptSetBigint < ActiveRecord::Migration[7.2]
  def change
    [:script_sets, :script_set_automatic_types, :script_set_automatic_set_inclusions, :script_set_script_inclusions, :script_set_set_inclusions].each do |table_name|
      change_column table_name, :id, :bigint, auto_increment: true
    end
  end
end
