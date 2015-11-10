class AddFlattrUsername < ActiveRecord::Migration
	def change
		add_column :users, :flattr_username, :string, :limit => 50
	end
end
