class DropScriptReportFk < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :scripts, :reports, column: :delete_report_id
  end
end
