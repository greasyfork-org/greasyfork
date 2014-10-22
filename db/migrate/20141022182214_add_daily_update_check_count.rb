class AddDailyUpdateCheckCount < ActiveRecord::Migration
	def change
		create_table :daily_update_check_counts do |t|
			t.integer :script_id, :null => false
			t.string :ip, :limit => 15, :null => false
		end
		add_index :daily_update_check_counts, [:script_id, :ip], :unique => true
		execute 'alter table daily_update_check_counts add column update_check_date timestamp not null default CURRENT_TIMESTAMP'
		create_table :update_check_counts do |t|
			t.integer :script_id, :null => false
			t.date :update_check_date, :null => false
			t.integer :update_checks, :null => false
		end
		add_index :update_check_counts, [:script_id, :update_check_date], :unique => true
	end
end
