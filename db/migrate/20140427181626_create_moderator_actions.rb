class CreateModeratorActions < ActiveRecord::Migration
	def change
		create_table :moderator_actions do |t|
			t.datetime :created_at, :null => false
			t.belongs_to :script
			t.references :moderator, :null => false
			t.string :action, :length => 50, :null => false
			t.string :reason, :length => 500, :null => false
		end
	end
end
