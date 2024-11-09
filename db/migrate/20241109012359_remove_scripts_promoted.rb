class RemoveScriptsPromoted < ActiveRecord::Migration[7.2]
  def change
    remove_column :scripts, :promoted
  end
end
