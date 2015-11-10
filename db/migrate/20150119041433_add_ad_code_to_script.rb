class AddAdCodeToScript < ActiveRecord::Migration
	def change
		add_column :scripts, :ad_method, :string, :limit => 2
	end
end
