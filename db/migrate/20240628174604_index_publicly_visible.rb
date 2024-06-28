class IndexPubliclyVisible < ActiveRecord::Migration[7.1]
  def change
    add_index :discussions, :publicly_visible
  end
end
