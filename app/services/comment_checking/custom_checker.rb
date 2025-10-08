module CommentChecking
  class CustomChecker
    def self.check(comment, ip:, user_agent:, referrer:)
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
        return CommentChecking::Result.new(true, text: "Matched custom check for '#{snippet}'.") if comment.text.include?(snippet)
      end

      [
        ['Mathematical Alphanumeric Symbols', /[\u{1d400}-\u{1d7ff}]/],
        ['Halfwidth and Fullwidth Forms', /[\uff00-\uffef]/],
      ].each do |name, pattern|
        return CommentChecking::Result.new(true, text: "Matched custom pattern check for '#{name}'.") if comment.text.match?(pattern)
      end

      CommentChecking::Result.not_spam
    end
  end
end
