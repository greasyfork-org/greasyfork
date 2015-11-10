class AddDeleteReasonToScripts < ActiveRecord::Migration
	def change
		add_column :scripts, :delete_reason, :string, :length => 500, :null => true
	end
end
