class AddPatternToScriptAppliesTo < ActiveRecord::Migration
	def change
		add_column :script_applies_tos, :pattern, :string, :limit => 1000, :null => false
		change_column :script_applies_tos, :display_text, :text, :limit => 500, :null => true
	end
end
