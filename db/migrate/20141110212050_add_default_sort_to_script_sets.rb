class AddDefaultSortToScriptSets < ActiveRecord::Migration
	def change
		add_column :script_sets, :default_sort, :string, :limit => 20
	end
end
