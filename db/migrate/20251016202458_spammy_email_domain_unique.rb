class SpammyEmailDomainUnique < ActiveRecord::Migration[8.0]
  def change
    remove_index :spammy_email_domains, :domain
    add_index :spammy_email_domains, :domain, unique: true
  end
end
