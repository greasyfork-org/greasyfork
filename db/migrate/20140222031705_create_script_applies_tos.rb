class CreateScriptAppliesTos < ActiveRecord::Migration
	def change
		create_table :script_applies_tos do |t|
			t.references :script, :index => true, :null => false
			t.text :display_text, :limit => 500, :null => false
			t.timestamps
		end
		reversible do |dir|
			dir.up do
				execute <<-SQL
					ALTER TABLE script_applies_tos
					ADD CONSTRAINT fk_script_applies_tos_script_id
					FOREIGN KEY (script_id)
					REFERENCES scripts(id)
				SQL
				Script.find_each do |script|
					script.script_applies_tos = script.script_versions.last.calculate_applies_to_names.map do |name|
						ScriptAppliesTo.new({:display_text => name})
					end
				end
			end
		end
	end
end
