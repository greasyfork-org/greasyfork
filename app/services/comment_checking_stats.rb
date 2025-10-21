class CommentCheckingStats
  STAT_TYPES = [:skips, :true_positives, :false_positives, :true_negatives, :false_negatives].freeze

  def initialize(from: 1.month.ago, to: Time.zone.tomorrow)
    @from = from
    @to = to
  end

  def overview
    stats = {}
    CommentCheckingService::STRATEGIES.map(&:name).sort.each do |strategy|
      stats[strategy] = s = { total: records(strategy:).count }
      STAT_TYPES.each do |result|
        s[result] = records(strategy:, result:).count
      end
      s[:processed] = s[:total] - s[:skips]
    end

    stats
  end

  def date_scope
    CommentCheckResult.joins(:comment).where(comment: { created_at: @from..@to })
  end

  def spam_comment_ids
    @spam_comment_ids ||= date_scope.joins(comment: :reports).where(reports: { reason: Report::REASON_SPAM, result: Report::RESULT_UPHELD }).pluck(:comment_id) +
                          date_scope.joins(comment: { discussion: :reports }).where(comment: { first_comment: true }, reports: { reason: Report::REASON_SPAM, result: Report::RESULT_UPHELD }).pluck(:comment_id) +
                          date_scope.where(comment: { spam_deleted: true }).pluck(:comment_id) +
                          date_scope.joins(comment: :discussion).where(comment: { first_comment: true, discussions: { spam_deleted: true } }).pluck(:comment_id)
  end

  def records(strategy: nil, result: nil)
    scope = date_scope
    scope = scope.where(strategy: strategy) if strategy.present?
    case result&.to_sym
    when nil
      scope
    when :skips
      scope.skipped
    when :processed
      scope.where(result: [:spam, :ham])
    when :true_positives
      scope.spam.where(comment_id: spam_comment_ids)
    when :false_positives
      scope.spam.where.not(comment_id: spam_comment_ids)
    when :true_negatives
      scope.ham.where.not(comment_id: spam_comment_ids)
    when :false_negatives
      scope.ham.where(comment_id: spam_comment_ids)
    else
      raise "Unknown result type: #{result}"
    end
  end
end
