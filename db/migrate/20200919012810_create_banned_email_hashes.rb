class CreateBannedEmailHashes < ActiveRecord::Migration[6.0]
  def change
    create_table :banned_email_hashes do |t|
      t.string :email_hash, null: false, length: 40
      t.datetime :deleted_at, null: false
      t.datetime :banned_at
    end
    add_index :banned_email_hashes, :email_hash, unique: true
  end
end
