module CommentChecking
  class CustomChecker < BaseCommentChecker
    def check
      string_to_check = [(@comment.discussion.title if @comment.first_comment?), @comment.text].compact.join("\n").downcase

      ['yxd02040608',
       'zrnq',
       'gmkm.zrnq.one',
       '🐧',
       'cbd ',
       'keto ',
       'hbyvipxnzj.buzz',
       'gmkm.zrnq.one',
       'cocaine',
       'coinbase',
       'lipomax',
       'www.8842030.com'].each do |snippet|
        return CommentChecking::Result.new(true, strategy: self, text: "Matched custom check for '#{snippet}'.") if string_to_check.include?(snippet)
      end

      [
        %w[facebook hack],
      ].each do |words|
        return CommentChecking::Result.new(true, strategy: self, text: "Matched custom check for [#{words.join(',')}].") if words.all? { |word| string_to_check.include?(word) }
      end

      [
        ['Mathematical Alphanumeric Symbols', /[\u{1d400}-\u{1d7ff}]/],
        ['Fullwidth Numbers', /[\uff10-\uff19]/],
        ['Fullwidth Capital Letters', /[\uff21-\uff3a]/],
        ['Fullwidth Small Letters', /[\uff41-\uff5a]/],
      ].each do |name, pattern|
        return CommentChecking::Result.new(true, strategy: self, text: "Matched custom pattern check for '#{name}'.") if string_to_check.match?(pattern)
      end

      CommentChecking::Result.ham(self)
    end
  end
end
