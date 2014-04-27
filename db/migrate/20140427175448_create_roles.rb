class CreateRoles < ActiveRecord::Migration
	def change
		create_table :roles do |t|
			t.string :name, :length => 20, :null => false
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into roles (name)
					values ('Administrator'), ('Moderator')
				EOF
			end
		end
		create_table :roles_users, id: false do |t|
			t.belongs_to :user, :null => false, :index => true
			t.belongs_to :role, :null => false, :index => true
		end
	end
end
