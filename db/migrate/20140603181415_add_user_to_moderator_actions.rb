class AddUserToModeratorActions < ActiveRecord::Migration
	def change
		add_column :moderator_actions, :user_id, :integer, :index => true
	end
end
