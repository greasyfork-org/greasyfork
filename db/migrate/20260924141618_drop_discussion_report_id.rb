class DropDiscussionReportId < ActiveRecord::Migration[8.1]
  def change
    remove_column :discussions, :report_id, :integer
  end
end
