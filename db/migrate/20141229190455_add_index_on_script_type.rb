class AddIndexOnScriptType < ActiveRecord::Migration
	def change
		add_index :scripts, :script_type_id
	end
end
