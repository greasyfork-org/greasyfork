class AddCompleteBlockToSpammyDomains < ActiveRecord::Migration[5.2]
  def change
    add_column :spammy_email_domains, :complete_block, :boolean, null: false, default: false
  end
end
