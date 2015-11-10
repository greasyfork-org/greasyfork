class ModifyFanScore < ActiveRecord::Migration
	def change
		change_column :scripts, :fan_score, :decimal, :precision => 3, :scale => 1
	end
end
