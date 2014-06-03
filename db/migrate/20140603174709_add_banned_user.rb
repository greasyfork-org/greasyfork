class AddBannedUser < ActiveRecord::Migration
	def change
		add_column :users, :banned, :boolean, :null => false, :default => false
	end
end
