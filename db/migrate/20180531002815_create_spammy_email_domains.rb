class CreateSpammyEmailDomains < ActiveRecord::Migration[5.2]
  def change
    create_table :spammy_email_domains do |t|
      t.string :domain, null: false, limit: 20, index: true
    end
  end
end
