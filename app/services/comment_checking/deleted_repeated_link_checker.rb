module CommentChecking
  class DeletedRepeatedLinkChecker
    def self.check(comment, ip:, user_agent:, referrer:)
      return CommentChecking::Result.not_spam(self) if comment.poster.created_at < 7.days.ago

      comments = find_recently_deleted_comments_with_link(comment)

      return CommentChecking::Result.not_spam(self) if comments.count < 2

      reports = comments.filter_map { |c| c.reports.upheld.take }

      CommentChecking::Result.new(true, strategy: self, text: "Post contains links in common with recently deleted comments: #{comments.map(&:url).join(' ')}", reports:)
    end

    def self.find_recently_deleted_comments_with_link(comment)
      links = comment.external_links
      return Comment.none unless links.any?

      text_condition = links.map { |_link| 'text LIKE ?' }.join(' OR ')
      condition_params = links.map { |link| "%#{Comment.sanitize_sql_like(link)}%" }
      comment.prior_deleted_comments(1.month).where(text_condition, *condition_params).reject(&:poster_deleted?)
    end
  end
end
