class AddTypeToScriptReports < ActiveRecord::Migration[5.2]
  def change
    add_column :script_reports, :report_type, :string, limit: 20
    execute 'update script_reports set report_type = "unauthorized_code" where report_type is null'
    change_column_null :script_reports, :report_type, false
  end
end
