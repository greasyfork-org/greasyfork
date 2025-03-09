module CommentChecking
  class RepeatedTextChecker
    def self.check(comment, ip:, user_agent:, referrer:)
      return CommentChecking::Result.not_spam if comment.poster.created_at < 7.days.ago

      previous_comments_by_same_user = comment.poster.comments.where(id: ...comment.id).where(text: comment.text).reject(&:poster_deleted?)

      if previous_comments_by_same_user.any?
        reports = previous_comments_by_same_user.filter_map { |c| c.reports.upheld.take }
        return CommentChecking::Result.new(true, text: "Matched previous comments by same user: #{previous_comments_by_same_user.map(&:url).join(' ')}", reports:)
      end

      CommentChecking::Result.not_spam
    end
  end
end
