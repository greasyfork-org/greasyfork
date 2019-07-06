class RenameScriptReportCopyDetails < ActiveRecord::Migration[5.2]
  def change
    rename_column :script_reports, :copy_details, :details
  end
end
