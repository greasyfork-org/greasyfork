class RenameRawColumnsOnCodeSimilarityFingerprints < ActiveRecord::Migration[8.1]
  def change
    change_table :code_similarity_fingerprints, bulk: true do |t|
      t.rename :raw_fingerprint, :fingerprint
      t.rename :raw_token_count, :token_count
    end
  end
end
