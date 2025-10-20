class CommentCheckingService
  STRATEGIES = [
    CommentChecking::AkismetChecker,
    CommentChecking::DefendiumChecker,
    CommentChecking::CustomChecker,
    CommentChecking::LinkCountChecker,
    CommentChecking::RepeatedTextChecker,
    CommentChecking::DeletedRepeatedTextChecker,
    CommentChecking::DeletedRepeatedLinkChecker,
    CommentChecking::OnlyLinkChecker,
  ].freeze

  def self.check(comment, ip:, user_agent:, referrer:)
    return if comment.reports.any?

    strategies = STRATEGIES.map { |s| s.new(comment, ip:, user_agent:, referrer:) }
    skipped_strategies, strategies_to_run = strategies.partition(&:skip?)
    spam_results, ham_results = strategies_to_run.map(&:check).partition(&:spam?)

    comment.comment_check_results.destroy_all
    CommentCheckResult.insert_all(
      skipped_strategies.map { |s| { comment_id: comment.id, strategy: s.class.name, result: :skipped } } +
      ham_results.map { |r| { comment_id: comment.id, strategy: r.strategy.class.name, result: :ham } } +
      spam_results.map { |r| { comment_id: comment.id, strategy: r.strategy.class.name, result: :spam } }
    )

    return if spam_results.empty?

    report = Report.create!(item: comment.reportable_item, auto_reporter: 'rainman', reason: Report::REASON_SPAM, private_explanation: spam_results.map(&:text).map { |t| "- #{t}" }.join("\n").truncate_bytes(65_535))

    if spam_results.count { |sr| !sr.strategy.is_a?(CommentChecking::DefendiumChecker) } >= 2 && strict_results?(comment)
      report.uphold!(moderator_notes: 'Blatant comment spam', ban_user: true, delete_comments: true, delete_scripts: true, automod: true)
    elsif report.item.is_a?(Discussion)
      report.item.update!(review_reason: Discussion::REVIEW_REASON_RAINMAN)
    end
  end

  def self.strict_results?(comment)
    comment.poster.created_at >= 7.days.ago
  end
end
