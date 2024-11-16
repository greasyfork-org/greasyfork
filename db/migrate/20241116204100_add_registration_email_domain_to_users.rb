class AddRegistrationEmailDomainToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :registration_email_domain, :string, limit: 100
  end
end
