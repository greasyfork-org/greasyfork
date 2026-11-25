class AddDeleteConfirmationForumContentToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :delete_confirmation_forum_content, :boolean, default: false, null: false
  end
end
