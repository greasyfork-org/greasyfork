class AddCompatibility < ActiveRecord::Migration
	def change
		create_table :browsers do |t|
			t.string :code, :null => false, :limit => 20
			t.string :name, :null => false, :limit => 20
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into browsers (code, name) values ('firefox', 'Firefox'), ('chrome', 'Chrome'), ('opera', 'Opera');
				EOF
			end
		end
		create_table :compatibilities do |t|
			t.belongs_to :script, :index => true, :null => false
			t.belongs_to :browser, :null => false
			t.boolean :compatible, :null => false
			t.string :comments, :limit => 200
		end
		add_foreign_key :compatibilities, :scripts, on_delete: :cascade
		add_foreign_key :compatibilities, :browsers, on_delete: :cascade
	end
end
