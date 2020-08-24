class AddAutoReporterToScriptReports < ActiveRecord::Migration[6.0]
  def change
    add_column :script_reports, :auto_reporter, :string, limit: 10
  end
end
