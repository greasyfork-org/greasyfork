class AddReportIdToDiscussions < ActiveRecord::Migration[6.1]
  def change
    add_column :discussions, :report_id, :integer, index: true
  end
end
