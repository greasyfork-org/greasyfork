class CodeSimilarityFingerprintJob < ApplicationJob
  queue_as :background

  def perform(script)
    unless script.js? && script.current_code
      self.class.delete_for_script_id(script.id)
      return
    end

    fingerprint = TokenShingleSimilarityScorer.build_fingerprint(script.current_code)
    CodeSimilarityFingerprint.store_fingerprint!(script.id, fingerprint)
    TokenShingleSimilarityJob.perform_later_unless_will_run(script.id)
  end

  def self.delete_for_script_id(script_id)
    CodeSimilarityFingerprint.where(script_id:).delete_all
    TokenShingleSimilarityJob.delete_for_script_id(script_id)
  end
end
