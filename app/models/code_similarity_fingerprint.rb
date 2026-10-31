class CodeSimilarityFingerprint < ApplicationRecord
  belongs_to :script
  has_many :hashes, class_name: 'CodeSimilarityFingerprintHash', foreign_key: :script_id, primary_key: :script_id,
                    inverse_of: :code_similarity_fingerprint, dependent: :delete_all

  def self.store_fingerprint!(script_id, fingerprint)
    hashes = TokenShingleSimilarityScorer.hashes_for_fingerprint(fingerprint.fetch(:fingerprint))
    deadlock_retries = 0

    begin
      transaction do
        upsert(
          {
            script_id:,
            fingerprint: fingerprint.fetch(:fingerprint),
            token_count: fingerprint.fetch(:token_count),
          }
        )
        CodeSimilarityFingerprintHash.where(script_id:).delete_all
        CodeSimilarityFingerprintHash.insert_all(hashes.map { |hash| { script_id:, fingerprint_hash: hash } }) if hashes.any?
      end
    rescue ActiveRecord::Deadlocked
      deadlock_retries += 1
      raise if deadlock_retries >= 10

      sleep([0.05 * (2**(deadlock_retries - 1)), 2.0].min + (rand * 0.1))
      retry
    end
  end
end
