class AddSafariAsBrowser < ActiveRecord::Migration
	def change
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into browsers (code, name) values ('safari', 'Safari');
				EOF
			end
		end
	end
end
