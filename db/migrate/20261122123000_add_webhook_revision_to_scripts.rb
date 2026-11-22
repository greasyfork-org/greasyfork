class AddWebhookRevisionToScripts < ActiveRecord::Migration[8.0]
  def change
    change_table :scripts, bulk: true do |t|
      t.string :webhook_repository, limit: 500
      t.string :webhook_ref, limit: 500
      t.string :webhook_previous_revision, limit: 64
      t.string :webhook_revision, limit: 64
    end
  end
end
