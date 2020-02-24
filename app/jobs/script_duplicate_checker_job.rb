require 'zlib'

class ScriptDuplicateCheckerJob < ApplicationJob
  def perform(script_id)
    now = Time.now

    script = Script.find(script_id)
    other_scripts = Script.not_deleted.where.not(id: script_id)

    last_run = ScriptSimilarity.where(script_id: script_id).maximum(:checked_at)
    if last_run && script.code_updated_at < last_run
      # Eliminate the ones we are up to date on
      up_to_date_script_ids = ScriptSimilarity.where(script_id: script_id).joins(:other_script).where(['code_updated_at < ?', last_run]).pluck(:other_script_id)
      other_scripts = other_scripts.where.not(id: up_to_date_script_ids)
    end

    results = CodeSimilarityScorer.get_similarities(script, other_scripts)

    if results.any?
      ScriptSimilarity.where(script_id: script_id).delete_all
      bulk_data = results.sort_by(&:last).last(100).map { |other_script_id, similarity| { script_id: script_id, other_script_id: other_script_id, similarity: similarity.round(3), checked_at: now } }
      ScriptSimilarity.upsert_all(bulk_data)
    end
  end
end