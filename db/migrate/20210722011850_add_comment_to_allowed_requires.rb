class AddCommentToAllowedRequires < ActiveRecord::Migration[6.1]
  def change
    add_column :allowed_requires, :comment, :text
  end
end
