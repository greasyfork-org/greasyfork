require 'defendium'

module CommentChecking
  class DefendiumChecker
    def self.check(comment, ip:, user_agent:, referrer:)
      is_spam = submit_to_defendium(comment, ip:, user_agent:, referrer:)

      return CommentChecking::Result.not_spam(self) unless is_spam

      CommentChecking::Result.new(true, strategy: self, text: 'Defendium result is spam.')
    end

    def self.submit_to_defendium(comment, ip:, user_agent:, referrer:)
      defendium = Defendium.new(Rails.application.credentials.defendium.api_key)
      defendium.check(
        content: comment.text,
        url: comment.url,
        ip:,
        user_agent:,
        referrer:,
        author: comment.poster&.name,
        languages: Rails.application.config.available_locales.keys.map { |l| l.tr('-', '_') }.join(', ')
      )
    end
  end
end
