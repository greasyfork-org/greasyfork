class DeleteDiscussionsOnReports < ActiveRecord::Migration[8.1]
  def change
    execute 'DELETE FROM discussions WHERE report_id IS NOT NULL'
  end
end
