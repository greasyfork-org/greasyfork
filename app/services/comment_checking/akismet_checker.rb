require 'akismet'

module CommentChecking
  class AkismetChecker
    def self.check(comment, ip:, user_agent:, referrer:)
      return CommentChecking::Result.new(false, text: 'No Akismet key defined') unless Akismet.api_key

      akismet_submission = AkismetSubmission.find_by(item: comment) || submit_to_akismet(comment, ip:, user_agent:, referrer:)

      return CommentChecking::Result.not_spam unless akismet_submission.result_spam

      CommentChecking::Result.new(true, text: akismet_submission.result_blatant ? 'Akismet result is blatant spam' : 'Akismet result is spam')
    end

    def self.submit_to_akismet(comment, ip:, user_agent:, referrer:)
      akismet_params = [
        ip,
        user_agent,
        {
          referrer:,
          post_url: comment.url,
          post_modified_at: comment.updated_at,
          type: 'forum-post',
          text: comment.text,
          created_at: comment.created_at,
          author: comment.poster&.name,
          author_email: comment.poster&.email,
          languages: Rails.application.config.available_locales.keys,
          env: {},
        },
      ]

      is_spam, is_blatant = Akismet.check(*akismet_params)

      AkismetSubmission.create!(item: comment, akismet_params:, result_spam: is_spam, result_blatant: is_blatant)
    end
  end
end
