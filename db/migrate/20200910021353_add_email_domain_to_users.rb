class AddEmailDomainToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :email_domain, :string, limit: 100, index: true
  end
end
