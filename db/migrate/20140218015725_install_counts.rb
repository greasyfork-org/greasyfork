class InstallCounts < ActiveRecord::Migration
	def change
		create_table :install_counts do |t|
			t.integer :script_id, :null => false
			t.date :install_date, :null => false
			t.integer :installs, :null => false
		end
		add_index :install_counts, [:script_id, :install_date], :unique => true
		add_column :scripts, :daily_installs, :integer, :null => false, :default => 0
		add_column :scripts, :total_installs, :integer, :null => false, :default => 0
	end
end
