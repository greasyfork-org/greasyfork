require 'akismet'

module CommentChecking
  class AkismetChecker < BaseCommentChecker
    def skip?
      !Akismet.api_key
    end

    def check
      akismet_submission = AkismetSubmission.find_by(item: @comment) || submit_to_akismet

      return CommentChecking::Result.not_spam(self) unless akismet_submission.result_spam

      CommentChecking::Result.new(true, strategy: self, text: akismet_submission.result_blatant ? 'Akismet result is blatant spam.' : 'Akismet result is spam.')
    end

    def submit_to_akismet
      akismet_params = [
        @ip,
        @user_agent,
        {
          referrer: @referrer,
          post_url: @comment.url,
          post_modified_at: @comment.updated_at,
          type: 'forum-post',
          text: @comment.text,
          created_at: @comment.created_at,
          author: @comment.poster&.name,
          author_email: @comment.poster&.email,
          languages: Rails.application.config.available_locales.keys,
          env: {},
        },
      ]

      is_spam, is_blatant = Akismet.check(*akismet_params)

      AkismetSubmission.create!(item: @comment, akismet_params:, result_spam: is_spam, result_blatant: is_blatant)
    end
  end
end
