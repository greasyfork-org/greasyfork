class AddFirstCommentToComments < ActiveRecord::Migration[6.0]
  def change
    add_column :comments, :first_comment, :boolean, null: false, default: false
  end
end
