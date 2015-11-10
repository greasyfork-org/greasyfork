class AddSupportUrlToScripts < ActiveRecord::Migration
	def change
		add_column :scripts, :support_url, :string, :limit => 500
	end
end
