class AddIndexToUserCanonicalEmail < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :canonical_email
  end
end
