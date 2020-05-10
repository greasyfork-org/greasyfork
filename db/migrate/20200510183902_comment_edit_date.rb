class CommentEditDate < ActiveRecord::Migration[6.0]
  def change
    add_column :comments, :edited_at, :datetime
  end
end
