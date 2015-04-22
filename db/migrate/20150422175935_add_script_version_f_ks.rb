class AddScriptVersionFKs < ActiveRecord::Migration
	def change
		add_foreign_key :localized_script_version_attributes, :script_versions, on_delete: :cascade
		add_foreign_key :screenshots_script_versions, :script_versions, on_delete: :cascade
	end
end
