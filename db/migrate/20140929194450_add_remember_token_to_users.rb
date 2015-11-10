class AddRememberTokenToUsers < ActiveRecord::Migration
	def change
		add_column :users, :remember_token, :string, :limit => 150, :index => true
	end
end
