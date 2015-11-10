class CreateScriptSets < ActiveRecord::Migration
	def change
		create_table :script_sets do |t|
			t.references :user, :null => false
			t.index :user_id
			t.string :name, :limit => 100, :null => false
			t.text :description, :limit => 500, :null => false
			t.timestamps
		end
		create_table :script_set_set_inclusions do |t|
			t.references :parent, :null => false
			t.index :parent_id
			t.references :child, :null => false
			t.index :child_id
			t.boolean :exclusion, :null => false, :default => false
		end
		create_table :script_set_script_inclusions do |t|
			t.references :parent, :null => false
			t.index :parent_id
			t.references :child, :null => false
			t.index :child_id
			t.boolean :exclusion, :null => false, :default => false
		end
		create_table :script_set_automatic_types do |t|
			t.string :name, :limit => 50, :null => false
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into script_set_automatic_types (name)
					values ('All scripts'), ('Scripts for site'), ('Scripts by user')
				EOF
			end
		end
		create_table :script_set_automatic_set_inclusions do |t|
			t.references :parent, :null => false
			t.index :parent_id
			t.references :script_set_automatic_type, :null => false
			t.index :script_set_automatic_type_id, :name => 'ssasi_script_set_automatic_type_id'
			t.string :value, :limit => 100
			t.boolean :exclusion, :null => false, :default => false
		end
	end
end
