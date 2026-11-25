module CommentChecking
  class DataCentreChecker < CommentChecking::BaseCommentChecker
    REVIEW_LOOKBACK = 1.week
    MAX_ACCOUNT_AGE = 1.week
    MIN_REVIEWERS = 5

    def check
      data_centre_ips = DataCentreIps.new
      return CommentChecking::Result.ham(self) unless data_centre_ips.data_centre?(@ip)

      other_reviews = Comment.joins(:discussion, :poster)
                             .includes(:discussion, :poster)
                             .where(first_comment: true, discussions: { script_id: @comment.script.id, rating: @comment.discussion.rating, created_at: (@comment.discussion.created_at - REVIEW_LOOKBACK)..@comment.discussion.created_at })
                             .where.not(poster_id: @comment.poster_id)
                             .order('discussions.created_at', 'discussions.id')
                             .select do |comment|
        comment.poster.created_at.between?(comment.discussion.created_at - MAX_ACCOUNT_AGE, comment.discussion.created_at) &&
          !comment.poster_deleted? && comment.poster.current_sign_in_ip.present? &&
          data_centre_ips.data_centre?(comment.poster.current_sign_in_ip)
      end.uniq(&:poster_id)

      return CommentChecking::Result.new(true, strategy: self, text: "Possible data centre review cluster - other reviews: #{other_reviews.map(&:url).join(' ')}") if other_reviews.size >= MIN_REVIEWERS - 1

      CommentChecking::Result.ham(self)
    end

    def skip?
      !@comment.first_comment? || @comment.script.nil? || !@comment.discussion.actual_rating? ||
        !@comment.poster.created_at.between?(@comment.discussion.created_at - MAX_ACCOUNT_AGE, @comment.discussion.created_at)
    end
  end
end
