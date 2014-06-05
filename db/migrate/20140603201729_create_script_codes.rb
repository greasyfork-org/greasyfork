class CreateScriptCodes < ActiveRecord::Migration
	def change
		create_table :script_codes do |t|
			t.integer :migration_id
			t.text :code, :length => 2000000, :null => false
		end
		# need a bigger column
		execute <<-SQL
			ALTER TABLE script_codes
			MODIFY COLUMN code MEDIUMTEXT NOT NULL
		SQL

		# code
		reversible do |dir|
			dir.up do
				execute <<-SQL
					INSERT INTO script_codes (migration_id, code)
					SELECT id, code FROM script_versions
				SQL
			end
		end
		add_column :script_versions, :script_code_id, :integer, :index => true, :null => false
		reversible do |dir|
			dir.up do
				execute <<-SQL
					UPDATE script_versions
					JOIN script_codes ON migration_id = script_versions.id
					SET script_code_id = script_codes.id
				SQL
				execute <<-SQL
					UPDATE script_codes SET migration_id = NULL
				SQL
			end
		end
		remove_column :script_versions, :code

		# rewritten code
		reversible do |dir|
			dir.up do
				execute <<-SQL
					INSERT INTO script_codes (migration_id, code)
					SELECT id, rewritten_code FROM script_versions
				SQL
			end
		end
		add_column :script_versions, :rewritten_script_code_id, :integer, :index => true, :null => false
		reversible do |dir|
			dir.up do
				execute <<-SQL
					UPDATE script_versions
					JOIN script_codes ON migration_id = script_versions.id
					SET rewritten_script_code_id = script_codes.id
				SQL
			end
		end
		remove_column :script_versions, :rewritten_code
		remove_column :script_codes, :migration_id
	end
end
