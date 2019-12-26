class AddCanonicalEmailToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :canonical_email, :string
  end
end
