class AddModeratorDeleted < ActiveRecord::Migration
	def change
		change_table :scripts do |t|
			t.boolean :moderator_deleted, :null => false, :default => false, :index => true
		end
	end
end
