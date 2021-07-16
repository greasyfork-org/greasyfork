module Admin
  class ScriptSimilaritiesController < BaseController
    def index
      @page = params[:page]&.to_i || 0
      @page = 0 unless @page.between?(0, 100)

      @top_similarities = ScriptSimilarity
                          .joins(:script, :other_script)
                          .where(scripts: { delete_type: nil }, other_scripts_script_similarities: { delete_type: nil })
                          .order(similarity: :desc, script_id: :asc, other_script_id: :asc)
                          .limit(100)
                          .offset(@page * 100)
      # This is slow
      # .includes(script: :localized_names, other_script: :localized_names)

      count_scope = Script.not_deleted
      @run_count = count_scope.where(id: ScriptSimilarity.select(:script_id).distinct).count
      @total_count = count_scope.count
    end
  end
end
