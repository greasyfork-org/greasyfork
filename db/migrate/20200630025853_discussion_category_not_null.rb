class DiscussionCategoryNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :discussions, :discussion_category_id, false
  end
end
