class AddLocaleToUser < ActiveRecord::Migration
	def change
		add_column :users, :locale_id, :int
	end
end
