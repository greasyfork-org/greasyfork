class AddNamespace < ActiveRecord::Migration
	def change
		add_column :scripts, :namespace, :string, :null => true, :limit => 500
	end
end
