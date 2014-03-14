class AddScriptSync < ActiveRecord::Migration
	def change
		create_table :script_sync_types do |t|
			t.string :name, :null => false, :length => 20
			t.string :description, :null => false, :length => 500
		end
		create_table :script_sync_sources do |t|
			t.string :name, :null => false, :length => 20
			t.string :description, :null => false, :length => 500
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into script_sync_types (id, name, description) values
					(1, 'Manual', 'Update from the source on demand.'),
					(2, 'Automatic', 'Update from the source automatically.');
				EOF
				execute <<-EOF
					insert into script_sync_sources (id, name, description) values
					(1, 'URL', 'Sync from an arbitrary URL.'),
					(2, 'userscripts.org', 'Sync from a script posted on userscripts.org');
				EOF
			end
		end
		change_table :scripts do |t|
			t.references :script_sync_type
			t.references :script_sync_source
			t.string :sync_identifier
			t.string :sync_error
			t.datetime :last_attempted_sync_date
			t.datetime :last_successful_sync_date
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					update scripts set
						sync_identifier = userscripts_id,
						script_sync_type_id = 1,
						script_sync_source_id = 2
					where userscripts_id is not null;
				EOF
			end
		end
	end
end
