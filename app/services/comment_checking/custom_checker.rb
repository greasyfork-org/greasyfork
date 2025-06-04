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
       'Cocaine'].each do |snippet|
        return CommentChecking::Result.new(true, text: "Matched custom check for '#{snippet}'.") if comment.text.include?(snippet)
      end

      CommentChecking::Result.not_spam
    end
  end
end
