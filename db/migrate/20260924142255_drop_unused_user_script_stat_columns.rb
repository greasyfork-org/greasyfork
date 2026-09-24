class DropUnusedUserScriptStatColumns < ActiveRecord::Migration[8.1]
  def change
    remove_columns :users, :stats_script_count, :stats_script_daily_installs, :stats_script_fan_score, :stats_script_last_created, :stats_script_last_updated, :stats_script_ratings, :stats_script_total_installs
  end
end
