class LongerSyncIdentifer < ActiveRecord::Migration[5.0]
	def change
		change_column :scripts, :sync_identifier, :string, limit: 500
	end
end
