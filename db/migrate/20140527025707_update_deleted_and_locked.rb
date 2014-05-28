class UpdateDeletedAndLocked < ActiveRecord::Migration
	def change
		create_table :script_delete_types do |t|
			t.string :name, :null => false, :limit => 10
			t.string :description, :null => false, :limit => 500
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into script_delete_types (name, description) values
					('Keep', 'Users who previously installed this script will keep it.'),
					('Blank', 'Users who previously installed this script will be updated to a blanked-out version. Suitable when the script has a negative effect on the sites it runs on.');
				EOF
			end
		end
		change_table :scripts do |t|
			t.belongs_to :script_delete_type, :index => true
			t.boolean :locked, :null => false, :default => false, :index => true
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					update scripts set locked = true, script_delete_type_id = 2 where moderator_deleted;
				EOF
				execute <<-EOF
					update scripts set script_delete_type_id = 1, script_type_id = 1 where script_type_id = 4;
				EOF
				execute <<-EOF
					delete from script_types where id = 4;
				EOF
			end
		end
		change_table :scripts do |t|
			t.remove :moderator_deleted
		end
	end
end
