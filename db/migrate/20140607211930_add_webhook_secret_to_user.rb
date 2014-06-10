class AddWebhookSecretToUser < ActiveRecord::Migration
	def change
		change_table :users do |t|
			t.string :webhook_secret, :limit => 128
		end
	end
end
