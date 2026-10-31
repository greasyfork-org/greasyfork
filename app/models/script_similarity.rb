class ScriptSimilarity < ApplicationRecord
  belongs_to :script
  belongs_to :other_script, class_name: 'Script'

  def self.other_scripts_and_similarities_for(script, min_similarity:, include_deleted: false)
    similarities = script.script_similarities
                         .includes(:other_script)
                         .where(similarity: min_similarity..)
                         .order(similarity: :desc, id: :asc)
                         .filter_map do |similarity|
      [similarity.other_script, similarity.similarity] if include_deleted || !similarity.other_script.deleted?
    end

    if similarities.any?
      where(other_script: script)
        .includes(:script)
        .where(similarity: min_similarity..)
        .order(similarity: :desc, id: :asc)
        .each do |similarity|
          similarities << [similarity.script, similarity.similarity] if include_deleted || !similarity.script.deleted?
        end
      similarities = similarities.sort_by(&:last).reverse.uniq(&:first).first(100)
    end

    similarities
  end
end
