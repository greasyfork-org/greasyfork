class CreateDisallowedCodes < ActiveRecord::Migration
	def change
		create_table :disallowed_codes do |t|
			t.string :pattern, :null => false, :length => 255
			t.string :description, :null => false, :length => 500
			t.timestamps
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into disallowed_codes (pattern, description) values
					('function Like\\\\(p\\\\)', 'Based off malware posted on userscripts.org like http://userscripts.org/scripts/review/181277')
				EOF
			end
		end
	end
end
