class AddNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :name, :string, :limit => 50, :null => false
  end
end
