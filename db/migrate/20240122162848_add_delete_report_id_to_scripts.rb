class AddDeleteReportIdToScripts < ActiveRecord::Migration[7.1]
  def change
    add_column :scripts, :delete_report_id, :integer
  end
end
