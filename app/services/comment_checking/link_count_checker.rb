module CommentChecking
  class LinkCountChecker < BaseCommentChecker
    def check
      links = @comment.external_links

      return CommentChecking::Result.not_spam(self) if links.count < 5

      CommentChecking::Result.new(true, strategy: self, text: "Post contains #{links.count} off-site links.")
    end
  end
end
