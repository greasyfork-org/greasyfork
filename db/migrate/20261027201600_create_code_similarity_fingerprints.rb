class CreateCodeSimilarityFingerprints < ActiveRecord::Migration[8.1]
  def change
    create_table :code_similarity_fingerprints do |t|
      t.bigint :script_id, null: false
      t.binary :raw_fingerprint, null: false
      t.integer :raw_token_count, null: false
      t.timestamps
    end
    add_index :code_similarity_fingerprints, :script_id, unique: true
    add_foreign_key :code_similarity_fingerprints, :scripts, on_delete: :cascade
  end
end
