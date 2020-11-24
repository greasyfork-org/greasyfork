class DropDjTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :delayed_jobs
  end
end
