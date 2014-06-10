class InsertWebhookSyncType < ActiveRecord::Migration
	def change
		reversible do |dir|
			dir.up do
				execute <<-EOF
					INSERT INTO script_sync_types (name, description) VALUES ('Webhook', 'Update when the file on GitHub is pushed to.')
				EOF
			end
		end
	end
end
