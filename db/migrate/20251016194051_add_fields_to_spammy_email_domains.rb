class AddFieldsToSpammyEmailDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :spammy_email_domains, :expires_at, :datetime
    add_column :spammy_email_domains, :block_count, :integer, default: 1, null: false
  end
end
