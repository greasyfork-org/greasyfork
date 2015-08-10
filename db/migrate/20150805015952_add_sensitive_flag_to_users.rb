class AddSensitiveFlagToUsers < ActiveRecord::Migration
	def change
		add_column :users, :show_sensitive, :boolean, null: false, default: true, index: true
	end
end
