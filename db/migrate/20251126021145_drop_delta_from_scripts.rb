class DropDeltaFromScripts < ActiveRecord::Migration[8.1]
  def change
    remove_column :scripts, :delta
  end
end
