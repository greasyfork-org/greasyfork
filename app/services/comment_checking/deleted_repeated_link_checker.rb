module CommentChecking
  class DeletedRepeatedLinkChecker < BaseCommentChecker
    def skip?
      @comment.poster.created_at < 7.days.ago
    end

    def check
      comments = find_recently_deleted_comments_with_link

      return CommentChecking::Result.not_spam(self) if comments.count < 2

      reports = comments.filter_map { |c| c.reports.upheld.take }

      CommentChecking::Result.new(true, strategy: self, text: "Post contains links in common with recently deleted comments: #{comments.map(&:url).join(' ')}", reports:)
    end

    def find_recently_deleted_comments_with_link
      links = @comment.external_links
      return Comment.none unless links.any?

      text_condition = links.map { |_link| 'text LIKE ?' }.join(' OR ')
      condition_params = links.map { |link| "%#{Comment.sanitize_sql_like(link)}%" }
      @comment.prior_deleted_comments(1.month).where(text_condition, *condition_params).reject(&:poster_deleted?)
    end
  end
end
