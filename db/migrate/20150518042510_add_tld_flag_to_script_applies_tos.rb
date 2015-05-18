class AddTldFlagToScriptAppliesTos < ActiveRecord::Migration
	def change
		add_column :script_applies_tos, :tld_extra, :boolean, null: false, default: false, index: true
	end
end
