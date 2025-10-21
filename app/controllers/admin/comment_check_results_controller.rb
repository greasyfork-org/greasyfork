module Admin
  class CommentCheckResultsController < BaseController
    def index
      params[:from] ||= 30.days.ago.to_date.to_s
      params[:to] ||= Time.zone.tomorrow.to_s
      @results = CommentCheckingStats.new(from: params[:from], to: params[:to]).overview
      @totals = @results.map(&:last).reduce({ total: 0, processed: 0, skips: 0, true_positives: 0, false_positives: 0, true_negatives: 0, false_negatives: 0 }) do |sum, stats|
        {
          total: sum[:total] + stats[:total],
          processed: sum[:processed] + stats[:processed],
          skips: sum[:skips] + stats[:skips],
          true_positives: sum[:true_positives] + stats[:true_positives],
          false_positives: sum[:false_positives] + stats[:false_positives],
          true_negatives: sum[:true_negatives] + stats[:true_negatives],
          false_negatives: sum[:false_negatives] + stats[:false_negatives],
        }
      end
    end

    def detail
      params[:from] ||= 30.days.ago.to_date.to_s
      params[:to] ||= Time.zone.tomorrow.to_s
      comment_ids = CommentCheckingStats.new(from: params[:from], to: params[:to]).records(strategy: params[:strategy], result: params[:result]).pluck(:comment_id)
      @results = CommentCheckResult.includes(:comment).where(comment_id: comment_ids.first(1000)).order('comment.created_at DESC, strategy')
      @results = @results.group_by(&:comment_id)
    end
  end
end
