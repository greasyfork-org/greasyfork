class DrpoApproveRedistribution < ActiveRecord::Migration[6.0]
  def change
    remove_column :scripts, :approve_redistribution
    remove_column :users, :approve_redistribution
  end
end
