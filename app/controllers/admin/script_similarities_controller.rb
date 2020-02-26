module Admin
  class ScriptSimilaritiesController < BaseController
    def index
      @top_similarities = ScriptSimilarity
                              .joins(:script, :other_script)
                              .where(scripts: { script_delete_type_id: nil }, other_scripts_script_similarities: { script_delete_type_id: nil })
                              .order(similarity: :desc)
                              .limit(100)
      @run_count = ScriptSimilarity.select(:script_id).distinct.count
      @total_count = Script.not_deleted.count
    end
  end
end