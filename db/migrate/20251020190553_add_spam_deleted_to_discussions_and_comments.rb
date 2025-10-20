class AddSpamDeletedToDiscussionsAndComments < ActiveRecord::Migration[8.0]
  def change
    add_column :discussions, :spam_deleted, :boolean, default: false, null: false
    add_column :comments, :spam_deleted, :boolean, default: false, null: false
  end
end
