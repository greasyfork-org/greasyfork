class AddCodeUpdatedAt < ActiveRecord::Migration
	def change
		add_column :scripts, :code_updated_at, :datetime, :null => false
		reversible do |dir|
			dir.up do
				execute <<-EOF
					update scripts set code_updated_at = updated_at
				EOF
			end
		end
	end
end
