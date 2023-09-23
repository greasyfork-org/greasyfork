class EnumScriptType < ActiveRecord::Migration[7.0]
  def change
    add_column :scripts, :script_type, :integer, default: 1, null: false
    execute 'update scripts set script_type = script_type_id'
  end
end
