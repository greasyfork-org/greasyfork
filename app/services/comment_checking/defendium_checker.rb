require 'defendium'

module CommentChecking
  class DefendiumChecker < BaseCommentChecker
    def check
      is_spam = submit_to_defendium

      return CommentChecking::Result.ham(self) unless is_spam

      CommentChecking::Result.new(true, strategy: self, text: 'Defendium result is spam.')
    end

    def submit_to_defendium
      defendium = Defendium.new(Rails.application.credentials.defendium.api_key)
      defendium.check(
        content: @comment.text,
        url: @comment.url,
        ip: @ip,
        user_agent: @user_agent,
        referrer: @referrer,
        author: @comment.poster&.name,
        languages: Rails.application.config.available_locales.keys.map { |l| l.tr('-', '_') }.join(', ')
      )
    end
  end
end
