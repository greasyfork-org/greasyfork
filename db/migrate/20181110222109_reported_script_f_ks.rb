class ReportedScriptFKs < ActiveRecord::Migration[5.2]
  def change
    change_column :script_reports, :script_id, :integer, null: false
    change_column :script_reports, :reference_script_id, :integer, null: false
    add_foreign_key :script_reports, :scripts, on_delete: :cascade
    add_foreign_key :script_reports, :scripts, column: :reference_script_id, on_delete: :cascade
  end
end
