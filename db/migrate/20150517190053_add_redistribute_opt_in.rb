class AddRedistributeOptIn < ActiveRecord::Migration
	def change
		add_column :users, :approve_redistribution, :boolean, index: true
		add_column :scripts, :approve_redistribution, :boolean, index: true
	end
end
