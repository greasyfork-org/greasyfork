class ScriptReportReferenceScriptOptional < ActiveRecord::Migration[5.2]
  def change
    change_column_null :script_reports, :reference_script_id, true
  end
end
