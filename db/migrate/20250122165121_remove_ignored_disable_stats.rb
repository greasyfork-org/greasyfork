class RemoveIgnoredDisableStats < ActiveRecord::Migration[8.0]
  def change
    remove_column :scripts, :disable_stats
  end
end
