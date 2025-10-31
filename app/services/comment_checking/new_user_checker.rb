require 'akismet'

module CommentChecking
  class NewUserChecker < BaseCommentChecker
    def skip?
      # Discussions only
      return true unless @comment.first_comment?

      # Not script reviews
      return true if @comment.discussion.for_script?

      # Only comments in made within an hour of registration
      @comment.created_at > @comment.poster.created_at + 1.hour
    end

    def check
      return CommentChecking::Result.ham(self) unless @comment.poster.discussions.not_for_script.where(created_at: ...@comment.discussion.created_at).any?

      CommentChecking::Result.new(true, strategy: self, text: 'Multiple discussions by new user within an hour of registering.')
    end
  end
end
