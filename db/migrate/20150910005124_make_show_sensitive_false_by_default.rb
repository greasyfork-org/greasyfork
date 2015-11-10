class MakeShowSensitiveFalseByDefault < ActiveRecord::Migration
	def change
		change_column :users, :show_sensitive, :boolean, null: :false, default: false
	end
end
