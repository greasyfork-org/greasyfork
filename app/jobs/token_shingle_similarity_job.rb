class TokenShingleSimilarityJob < ApplicationJob
  queue_as :background

  def perform(script_id, only_higher_ids: false)
    script = Script.find_by(id: script_id)
    return unless script

    fingerprint = CodeSimilarityFingerprint.find_by(script_id:)
    unless script.js? && fingerprint
      self.class.delete_for_script_id(script_id)
      return
    end

    similarities = TokenShingleSimilarityScorer.get_similarities(script, only_higher_ids:)
    checked_at = Time.current
    rows = similarities.filter_map do |other_script_id, similarity|
      next if similarity < TokenShingleSimilarityScorer::MIN_DISPLAYED_SIMILARITY

      {
        script_id: [script_id, other_script_id].min,
        other_script_id: [script_id, other_script_id].max,
        similarity: similarity.round(3),
        checked_at:,
      }
    end

    TokenShingleSimilarity.transaction do
      if only_higher_ids
        TokenShingleSimilarity.where(script_id:).delete_all
      else
        self.class.delete_for_script_id(script_id)
      end
      TokenShingleSimilarity.upsert_all(rows) if rows.any?
    end
  end

  def self.delete_for_script_id(script_id)
    TokenShingleSimilarity.where(script_id:).or(TokenShingleSimilarity.where(other_script_id: script_id)).delete_all
  end
end
