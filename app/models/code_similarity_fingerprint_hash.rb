class CodeSimilarityFingerprintHash < ApplicationRecord
  belongs_to :code_similarity_fingerprint, foreign_key: :script_id, primary_key: :script_id, inverse_of: :hashes
end
