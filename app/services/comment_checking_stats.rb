class CommentCheckingStats
  def initialize(from: 1.month.ago, to: Time.zone.now)
    @from = from
    @to = to
  end

  def run
    comments = CommentCheckResult.joins(:comment).where(comments: { created_at: @from..@to })
    spam_comment_ids = comments.joins(comment: :reports).where(reports: { reason: Report::REASON_SPAM, result: Report::RESULT_UPHELD }).pluck(:id)

    stats = {}
    CommentCheckingService::STRATEGIES.each do |strategy|
      results_for_strategy = comments.where(strategy: strategy.name)

      # This is not correctly accounting for users manually banned
      stats[strategy.name] = {
        total: results_for_strategy.count,
        skips: results_for_strategy.skipped.count,
        true_positives: results_for_strategy.spam.where(spam_comment_ids:).count,
        false_positives: results_for_strategy.spam.where.not(spam_comment_ids:).count,
        true_negatives: results_for_strategy.not_spam.where.not(spam_comment_ids:).count,
        false_negatives: results_for_strategy.not_spam.where(spam_comment_ids:).count,
      }
    end

    stats
  end
end
