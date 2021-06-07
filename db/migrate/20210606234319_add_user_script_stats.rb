class AddUserScriptStats < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :stats_script_count, :integer, default: 0, null: false, index: true
    add_column :users, :stats_script_total_installs, :integer, default: 0, null: false, index: true
    add_column :users, :stats_script_daily_installs, :integer, default: 0, null: false, index: true
    add_column :users, :stats_script_fan_score, :decimal, precision: 6, scale: 1, default: 0, null: false, index: true
    add_column :users, :stats_script_ratings, :integer, default: 0, null: false, index: true
    add_column :users, :stats_script_last_created, :datetime, index: true
    add_column :users, :stats_script_last_updated, :datetime, index: true
  end
end