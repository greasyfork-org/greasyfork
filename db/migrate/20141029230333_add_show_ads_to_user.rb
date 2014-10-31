class AddShowAdsToUser < ActiveRecord::Migration
	def change
		add_column :users, :show_ads, :boolean, :null => false, :default => true
		execute 'update users join scripts on scripts.user_id = users.id set show_ads = false'
	end
end
