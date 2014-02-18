class CreateAllowedRequires < ActiveRecord::Migration
	def change
		create_table :allowed_requires do |t|
			t.string :pattern, :null => false, :length => 255
			t.string :name, :null => false, :length => 100
			t.timestamps
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into allowed_requires (pattern, name) values
					('^https?:\\\\/\\\\/ajax\\\\.googleapis\\\\.com\\\\/.*', 'Google Hosted Libraries')
				EOF
			end
		end
	end
end
