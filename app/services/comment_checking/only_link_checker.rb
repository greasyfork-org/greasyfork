module CommentChecking
  class OnlyLinkChecker < BaseCommentChecker
    def skip?
      @comment.poster.created_at < 7.days.ago
    end

    def check
      doc = @comment.text_as_doc
      return CommentChecking::Result.ham(self) if doc.text.squish.empty?

      doc.search('a[href]').each { |a| a.remove unless Comment::INTERNAL_LINK_PREFIXES.any? { |prefix| a.attr(:href).starts_with?(prefix) } }
      linkless_doc = doc.text.squish

      return CommentChecking::Result.ham(self) if linkless_doc.present?

      CommentChecking::Result.new(true, strategy: self, text: 'Post contains only links.')
    end
  end
end
