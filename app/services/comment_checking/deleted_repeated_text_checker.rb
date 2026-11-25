module CommentChecking
  class DeletedRepeatedTextChecker < BaseCommentChecker
    def skip?
      @comment.poster.created_at < 7.days.ago
    end

    def check
      previously_deleted_comments = @comment.prior_deleted_comments(1.month).where(text: @comment.text).reject(&:poster_deleted?)

      if previously_deleted_comments.any?
        reports = previously_deleted_comments.filter_map { |c| c.reports.upheld.take }
        duplicate = previously_deleted_comments.any? { |comment| comment.poster_id.present? && comment.poster_id == @comment.poster_id }
        return CommentChecking::Result.new(true, strategy: self, text: "Matched recent deleted comments: #{previously_deleted_comments.map(&:url).join(' ')}", reports:, duplicate:)
      end

      CommentChecking::Result.ham(self)
    end
  end
end
