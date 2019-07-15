class AddBlockedToSiteApplications < ActiveRecord::Migration[5.2]
  def change
    change_table :site_applications do |t|
      t.boolean :blocked, null: false, default: false
      t.string :blocked_message
    end
  end
end
