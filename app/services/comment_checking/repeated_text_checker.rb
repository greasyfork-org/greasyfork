module CommentChecking
  class RepeatedTextChecker < BaseCommentChecker
    def skip?
      @comment.poster.created_at < 7.days.ago
    end

    def check
      previous_comments_by_same_user = @comment.poster.comments.where(id: ...@comment.id).where(text: @comment.text).reject(&:poster_deleted?)

      if previous_comments_by_same_user.any?
        reports = previous_comments_by_same_user.filter_map { |c| c.reports.upheld.take }
        return CommentChecking::Result.new(true, strategy: self, text: "Matched previous comments by same user: #{previous_comments_by_same_user.map(&:url).join(' ')}", reports:)
      end

      CommentChecking::Result.ham(self)
    end
  end
end
