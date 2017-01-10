class AddDeletionConfirmToUsers < ActiveRecord::Migration[5.0]
  def change
    change_table :users do |t|
      t.column :delete_confirmation_key, :string, length: 32
      t.column :delete_confirmation_expiry, :datetime
    end
  end
end
