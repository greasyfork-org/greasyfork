class CreateIdentity < ActiveRecord::Migration
	def up
		create_table :identities do |t|
			t.belongs_to :user, :null => false
			t.index [:uid, :provider], :unique => true
			t.string :provider, :limit => 255, :null => false
			t.string :uid, :limit => 255, :null => false
			t.string :url, :limit => 500
			t.boolean :syncing, :null => false
		end
		change_column :users, :encrypted_password, :string, :limit => 255, :null => true
	end

	def down
		drop_table :identities
		change_column :users, :encrypted_password, :string, :limit => 255, :null => false
	end
end
