# rubocop:disable Rails/BulkChangeTable
class DailyUpdateCheckCountsUniquePerDay < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :daily_update_check_counts, :scripts
    add_column :daily_update_check_counts, :update_day, :date, as: 'DATE(update_date)', stored: true
    remove_index :daily_update_check_counts, name: :update_script_id_and_ip
    add_index :daily_update_check_counts, [:script_id, :ip, :update_day], unique: true, name: :update_script_id_and_ip_and_day
    add_index :daily_update_check_counts, :update_day
  end

  def down
    remove_index :daily_update_check_counts, :update_day
    remove_index :daily_update_check_counts, name: :update_script_id_and_ip_and_day
    execute 'DELETE d1 FROM daily_update_check_counts d1 JOIN daily_update_check_counts d2 ON d1.script_id = d2.script_id AND d1.ip = d2.ip AND d1.update_date > d2.update_date'
    add_index :daily_update_check_counts, [:script_id, :ip], unique: true, name: :update_script_id_and_ip
    remove_column :daily_update_check_counts, :update_day
    add_foreign_key :daily_update_check_counts, :scripts, on_delete: :cascade
  end
end
# rubocop:enable Rails/BulkChangeTable
