class AddShortNameToScriptTypes < ActiveRecord::Migration
	def change
		add_column :script_types, :short_name, :string, :limit => 10
		reversible do |dir|
			dir.up do
				execute <<-EOF
					update script_types set short_name = 'public' where id = 1;
				EOF
				execute <<-EOF
					update script_types set short_name = 'unlisted' where id = 2;
				EOF
				execute <<-EOF
					update script_types set short_name = 'library' where id = 3;
				EOF
				execute <<-EOF
					update script_types set short_name = 'deleted' where id = 4;
				EOF
			end
		end
	end
end
