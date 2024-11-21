class AddDeviseTwoFactorToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :consumed_timestep, :integer
    add_column :users, :otp_required_for_login, :boolean
  end
end
