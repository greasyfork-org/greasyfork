class Reconfirmable < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :unconfirmed_email, :string
  end
end
