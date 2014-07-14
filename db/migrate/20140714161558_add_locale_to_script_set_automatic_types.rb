class AddLocaleToScriptSetAutomaticTypes < ActiveRecord::Migration
	def change
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into script_set_automatic_types (name)
					values ('Scripts by language')
				EOF
			end
		end
	end
end
