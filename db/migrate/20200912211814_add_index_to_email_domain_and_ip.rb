class AddIndexToEmailDomainAndIp < ActiveRecord::Migration[6.0]
  def change
    add_index :users, [:email_domain, :current_sign_in_ip, :banned_at]
  end
end
