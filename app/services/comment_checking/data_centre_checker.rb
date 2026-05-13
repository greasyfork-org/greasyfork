module CommentChecking
  class DataCentreChecker < CommentChecking::BaseCommentChecker
    def check
      return CommentChecking::Result.new(true, strategy: self, text: 'Comment may be from a data centre.') if DataCentreIps.new.data_centre?(@ip)

      CommentChecking::Result.ham(self)
    end

    def skip?
      # Only check the user's first comment.
      @comment.poster.comments.first != @comment
    end
  end
end
