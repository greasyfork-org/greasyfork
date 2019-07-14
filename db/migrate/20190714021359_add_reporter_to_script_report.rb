class AddReporterToScriptReport < ActiveRecord::Migration[5.2]
  def change
    add_column :script_reports, :reporter_id, :integer
    add_foreign_key :script_reports, :users, column: :reporter_id, on_delete: :nullify
  end
end
