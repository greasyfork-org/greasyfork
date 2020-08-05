class AddDiscussionsReadSinceToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :discussions_read_since, :datetime
  end
end
