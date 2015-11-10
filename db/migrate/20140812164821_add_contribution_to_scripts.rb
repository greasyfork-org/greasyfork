class AddContributionToScripts < ActiveRecord::Migration
	def change
		add_column :scripts, :contribution_url, :string, :length => 500, :null => true
		add_column :scripts, :contribution_amount, :string, :length => 50, :null => true
	end
end
