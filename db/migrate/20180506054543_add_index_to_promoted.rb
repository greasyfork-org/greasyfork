class AddIndexToPromoted < ActiveRecord::Migration[5.1]
  def change
    add_index :scripts, :promoted
  end
end
