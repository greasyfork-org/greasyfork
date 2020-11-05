class DropUnusedUserColumns < ActiveRecord::Migration[6.0]
  def change
    remove_columns :users, :banned, :flattr_username
  end
end
