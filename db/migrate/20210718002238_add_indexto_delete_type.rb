class AddIndextoDeleteType < ActiveRecord::Migration[6.1]
  def change
    add_index :scripts, :delete_type
  end
end
