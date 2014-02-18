class AddDailyInstallCount < ActiveRecord::Migration
	def change
		create_table :daily_install_counts do |t|
			t.integer :script_id, :null => false
			t.string :ip, :limit => 15, :null => false
		end
		add_index :daily_install_counts, [:script_id, :ip], :unique => true
		execute 'alter table daily_install_counts add column install_date timestamp not null default CURRENT_TIMESTAMP'
	end
end
