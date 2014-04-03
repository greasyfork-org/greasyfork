class AddDeltaToScripts < ActiveRecord::Migration
  def change
    add_column :scripts, :delta, :boolean, :default => true, :null => false
    add_index  :scripts, :delta
  end
end
