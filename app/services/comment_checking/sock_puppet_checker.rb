module CommentChecking
  class SockPuppetChecker < BaseCommentChecker
    def skip?
      !@comment.first_comment? || @comment.script.nil?
    end

    def check
      recent_discussions_by_same_ip = Discussion.joins(:poster).where(script: @comment.script, poster: { current_sign_in_ip: @comment.poster.current_sign_in_ip }, created_at: 1.day.ago..).where.not(poster: @comment.poster).load

      return CommentChecking::Result.ham(self) if recent_discussions_by_same_ip.none?

      CommentChecking::Result.new(true, strategy: self, text: "Possible sock puppet - matched previous discussions: #{recent_discussions_by_same_ip.map(&:url).join(' ')}")
    end
  end
end
