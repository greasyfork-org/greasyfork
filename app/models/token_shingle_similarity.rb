class TokenShingleSimilarity < ApplicationRecord
  belongs_to :script, inverse_of: :token_shingle_similarities
  belongs_to :other_script, class_name: 'Script', inverse_of: :token_shingle_similarities_as_other_script

  def self.other_scripts_and_similarities_for(script, include_deleted: false)
    where(script_id: script.id)
      .or(where(other_script_id: script.id))
      .includes(:script, :other_script)
      .order(similarity: :desc, id: :asc)
      .filter_map do |similarity|
        other_script = (similarity.script_id == script.id) ? similarity.other_script : similarity.script
        [other_script, similarity.similarity] if include_deleted || !other_script.deleted?
      end
      .first(100)
  end
end
