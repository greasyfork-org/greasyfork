class CreateScriptVersions < ActiveRecord::Migration
	def change
		create_table :script_versions do |t|
			t.references :script, :index => true, :null => false
			t.text :changelog, :limit => 500
			t.text :additional_info, :length => 10000
			t.text :version, :length => 20, :null => false
			t.text :code, :length => 500000, :null => false
			t.text :rewritten_code, :length => 500000, :null => false
			t.timestamps
		end
		execute <<-SQL
			ALTER TABLE script_versions
			ADD CONSTRAINT fk_script_versions_script_id
			FOREIGN KEY (script_id)
			REFERENCES scripts(id),
			MODIFY COLUMN code MEDIUMTEXT NOT NULL,
			MODIFY COLUMN rewritten_code MEDIUMTEXT NOT NULL
		SQL
	end
end
