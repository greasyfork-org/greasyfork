class AddFanScore < ActiveRecord::Migration
	def change
		add_column :scripts, :fan_score, :integer, :null => false, :default => 0
	end
end
