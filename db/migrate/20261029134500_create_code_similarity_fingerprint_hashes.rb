class CreateCodeSimilarityFingerprintHashes < ActiveRecord::Migration[8.1]
  def change
    create_table :code_similarity_fingerprint_hashes, id: false do |t|
      t.bigint :script_id, null: false
      t.binary :fingerprint_hash, limit: 8, null: false
      t.index [:script_id, :fingerprint_hash],
              unique: true,
              name: 'index_similarity_fingerprint_hashes_on_script_and_hash'
      t.index :fingerprint_hash, name: 'index_similarity_fingerprint_hashes_on_hash'
    end
    add_foreign_key :code_similarity_fingerprint_hashes, :code_similarity_fingerprints, column: :script_id, primary_key: :script_id, on_delete: :cascade
  end
end
