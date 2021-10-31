class AddNoStatsToScripts < ActiveRecord::Migration[6.1]
  def change
    add_column :scripts, :disable_stats, :boolean, default: false, null: false
  end
end
