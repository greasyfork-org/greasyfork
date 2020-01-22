class IndexUsersName < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :name
  end
end
