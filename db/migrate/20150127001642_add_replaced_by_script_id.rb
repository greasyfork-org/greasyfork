class AddReplacedByScriptId < ActiveRecord::Migration
	def change
		add_column :scripts, :replaced_by_script_id, :int
	end
end
