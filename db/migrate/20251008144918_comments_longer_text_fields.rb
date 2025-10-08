class CommentsLongerTextFields < ActiveRecord::Migration[8.0]
  def change
  
    change_column :comments, :text, :text, limit: 1_000_000, null: false
    change_column :comments, :plain_text, :text, limit: 1_000_000
  end
end
