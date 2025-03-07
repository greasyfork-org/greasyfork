module CommentChecking
  class DeletedRepeatedTextChecker
    def self.check(comment, ip:, user_agent:, referrer:)
      return CommentChecking::Result.not_spam if comment.poster.created_at < 7.days.ago

      previously_deleted_comments = comment.prior_deleted_comments(1.month).where(text: comment.text)

      if previously_deleted_comments.any?
        reports = previously_deleted_comments.filter_map { |c| c.reports.upheld.take }
        return CommentChecking::Result.new(true, text: "Matched recent deleted comments: #{previously_deleted_comments.map(&:url).join(' ')}", reports:)
      end

      CommentChecking::Result.not_spam
    end
  end
end
