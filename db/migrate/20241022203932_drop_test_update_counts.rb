class DropTestUpdateCounts < ActiveRecord::Migration[7.2]
  def change
    drop_table :test_update_counts
  end
end
