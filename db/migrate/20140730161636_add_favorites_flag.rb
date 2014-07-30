class AddFavoritesFlag < ActiveRecord::Migration
	def change
		add_column :script_sets, :favorite, :boolean, :null => false, :default => false
	end
end
