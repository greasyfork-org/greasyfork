class AddLocationsToCodeSimilarityFingerprints < ActiveRecord::Migration[8.1]
  def change
    change_table :code_similarity_fingerprints, bulk: true do |t|
      t.json :locations
      t.bigint :source_version_id
    end
  end
end
