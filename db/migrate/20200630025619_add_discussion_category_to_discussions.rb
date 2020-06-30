class AddDiscussionCategoryToDiscussions < ActiveRecord::Migration[6.0]
  def change
    add_column :discussions, :discussion_category_id, :integer, index: true
  end
end
