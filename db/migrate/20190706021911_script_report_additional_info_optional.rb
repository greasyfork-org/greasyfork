class ScriptReportAdditionalInfoOptional < ActiveRecord::Migration[5.2]
  def change
    change_column_null :script_reports, :additional_info, true
  end
end
