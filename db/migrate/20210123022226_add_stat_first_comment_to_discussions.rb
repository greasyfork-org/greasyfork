class AddStatFirstCommentToDiscussions < ActiveRecord::Migration[6.1]
  def change
    add_column :discussions, :stat_first_comment_id, :integer
  end
end
