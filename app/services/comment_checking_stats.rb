class CommentCheckingStats
  STAT_TYPES = [:skips, :true_positives, :false_positives, :true_negatives, :false_negatives, :pending, :unreviewed].freeze

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
    @spam_comment_ids ||= report_comment_ids(Report.where(result: Report::RESULT_UPHELD, automod_resolved: false).where.not(resolver_id: nil).where('COALESCE(moderator_reason_override, reason) = ?', Report::REASON_SPAM), after_edit: true)
  end

  def pending_comment_ids
    @pending_comment_ids ||= report_comment_ids(Report.unresolved) - spam_comment_ids
  end

  def ham_comment_ids
    @ham_comment_ids ||= report_comment_ids(Report.where(reason: Report::REASON_SPAM, result: Report::RESULT_DISMISSED).where.not(resolver_id: nil), after_edit: true) - spam_comment_ids - pending_comment_ids
  end

  def report_comment_ids(reports, after_edit: false)
    ids = reports.select(:id)
    comment_reports = date_scope.joins(comment: :reports).where(reports: { id: ids })
    discussion_reports = date_scope.joins(comment: { discussion: :reports }).where(comment: { first_comment: true }, reports: { id: ids })
    if after_edit
      condition = 'comment.edited_at IS NULL OR reports.updated_at >= comment.edited_at'
      comment_reports = comment_reports.where(condition)
      discussion_reports = discussion_reports.where(condition)
    end
    (comment_reports.distinct.pluck(:comment_id) + discussion_reports.distinct.pluck(:comment_id)).uniq
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
      scope.spam.where(comment_id: ham_comment_ids)
    when :true_negatives
      scope.ham.where(comment_id: ham_comment_ids)
    when :false_negatives
      scope.ham.where(comment_id: spam_comment_ids)
    when :pending
      scope.where(result: [:spam, :ham], comment_id: pending_comment_ids)
    when :unreviewed
      scope.where(result: [:spam, :ham]).where.not(comment_id: spam_comment_ids + pending_comment_ids + ham_comment_ids)
    else
      raise "Unknown result type: #{result}"
    end
  end

  def misses
    hit_comment_ids = CommentCheckResult.where(comment_id: spam_comment_ids).spam.distinct('comment_id').pluck(:comment_id)
    miss_comment_ids = spam_comment_ids - hit_comment_ids
    CommentCheckResult.where(comment_id: miss_comment_ids)
  end
end
