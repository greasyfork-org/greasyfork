class AddScriptType < ActiveRecord::Migration
	def change
		create_table :script_types do |t|
			t.string :name, :null => false, :length => 20
			t.string :description, :null => false, :length => 500
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into script_types (id, name, description) values
					(1, 'Public user script', 'A user script for all to see and use.'),
					(2, 'Unlisted user script', 'A user script for (semi-)private use. Available by direct access, but not linked to from anywhere on Greasy Fork.'),
					(3, 'Library', 'A script intended to be @require-d from other scripts and not installed directly.'),
					(4, 'Deleted', 'Unlisted and uninstallable.')
				EOF
			end
		end
		change_table :scripts do |t|
			t.references :script_type, :null => false, :default => 1
		end
	end
end
