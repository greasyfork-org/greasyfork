class AddIndexToDiscussionsReportId < ActiveRecord::Migration[7.1]
  def change
    add_index :discussions, :report_id
  end
end
