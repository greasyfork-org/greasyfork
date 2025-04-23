module CommentChecking
  class OnlyLinkChecker
    def self.check(comment, ip:, user_agent:, referrer:)
      return CommentChecking::Result.not_spam if comment.poster.created_at < 7.days.ago

      doc = comment.text_as_doc
      return CommentChecking::Result.not_spam if doc.text.squish.empty?

      doc.search('a[href]').each { |a| a.remove unless Comment::INTERNAL_LINK_PREFIXES.any? { |prefix| a.attr(:href).starts_with?(prefix) } }
      linkless_doc = doc.text.squish

      return CommentChecking::Result.not_spam if linkless_doc.present?

      CommentChecking::Result.new(true, text: 'Post contains only links.')
    end
  end
end
