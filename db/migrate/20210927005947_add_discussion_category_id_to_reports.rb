class AddDiscussionCategoryIdToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :discussion_category_id, :bigint
  end
end
