class AddUniqueIndexUserName < ActiveRecord::Migration[6.0]
  def change
    remove_index :users, :name
    add_index :users, :name, unique: true
  end
end
