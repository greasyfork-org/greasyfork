Cclass CreateScripts < ActiveRecord::Migration
	def change
		create_table :scripts do |t|
			t.string :name, :limit => 100, :null => false
			t.text :description, :limit => 500, :null => false
			t.text :additional_info, :length => 10000
			t.references :user, :index => true, :null => false
			t.timestamps
		end
		execute <<-SQL
			ALTER TABLE scripts
			ADD CONSTRAINT fk_scripts_user_id
			FOREIGN KEY (user_id)
			REFERENCES users(id)
		SQL
	end
end
