module CommentChecking
  class LinkCountChecker < BaseCommentChecker
    def check
      links = @comment.external_links

      return CommentChecking::Result.ham(self) if links.count < 5

      CommentChecking::Result.new(true, strategy: self, text: "Post contains #{links.count} off-site links.", weight: (links.count >= 10) ? 2 : 1)
    end
  end
end
