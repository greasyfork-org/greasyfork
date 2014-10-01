class AddSyncUrlToLocalizedScriptAttributes < ActiveRecord::Migration
	def change
		add_column :localized_script_attributes, :sync_identifier, :string, :limit => 255
		add_column :localized_script_attributes, :sync_source_id, :int
	end
end
