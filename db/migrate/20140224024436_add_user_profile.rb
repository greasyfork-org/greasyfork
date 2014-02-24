class AddUserProfile < ActiveRecord::Migration
	def change
		add_column :users, :profile, :string, :limit => 10000
	end
end
