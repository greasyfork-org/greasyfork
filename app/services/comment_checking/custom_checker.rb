module CommentChecking
  class CustomChecker < BaseCommentChecker
    def check
      ['yxd02040608',
       'zrnq',
       'gmkm.zrnq.one',
       '🐧',
       'CBD ',
       'Keto ',
       'hbyvipxnzj.buzz',
       'gmkm.zrnq.one',
       'Cocaine',
       'Coinbase',
       'Lipomax',
       'www.8842030.com'].each do |snippet|
        return CommentChecking::Result.new(true, strategy: self, text: "Matched custom check for '#{snippet}'.") if @comment.text.include?(snippet)
      end

      [
        ['Mathematical Alphanumeric Symbols', /[\u{1d400}-\u{1d7ff}]/],
        ['Fullwidth Numbers', /[\uff10-\uff19]/],
        ['Fullwidth Capital Letters', /[\uff21-\uff3a]/],
        ['Fullwidth Small Letters', /[\uff41-\uff5a]/],
      ].each do |name, pattern|
        return CommentChecking::Result.new(true, strategy: self, text: "Matched custom pattern check for '#{name}'.") if @comment.text.match?(pattern)
      end

      CommentChecking::Result.not_spam(self)
    end
  end
end
