class LongerSpammyEmailDomain < ActiveRecord::Migration[8.1]
  def change
    change_column :spammy_email_domains, :domain, :string, limit: 50
  end
end
