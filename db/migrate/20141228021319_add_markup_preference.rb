class AddMarkupPreference < ActiveRecord::Migration
	def change
		add_column :users, :preferred_markup, :string, :limit => 10, :default => 'html', :null => false
	end
end
