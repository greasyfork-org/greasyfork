class CreateSubresourceIntegrityHashes < ActiveRecord::Migration[7.0]
  def change
    create_table :subresource_integrity_hashes do |t|
      t.belongs_to :subresource, null: false
      t.string :algorithm, limit: 20, null: false
      t.string :encoding, limit: 10, null: false
      t.string :integrity_hash, limit: 128, null: false
    end
  end
end
