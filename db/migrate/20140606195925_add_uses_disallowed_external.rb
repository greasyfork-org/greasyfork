class AddUsesDisallowedExternal < ActiveRecord::Migration
	def change
		add_column :scripts, :uses_disallowed_external, :boolean, :null => false, :default => true, :index => true
	end
end
