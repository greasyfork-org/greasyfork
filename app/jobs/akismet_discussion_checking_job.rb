class AkismetDiscussionCheckingJob < ApplicationJob
  queue_as :low

  def perform(discussion, ip, user_agent, referrer)
    return unless Akismet.api_key

    akismet_params = [
      ip,
      user_agent,
      {
        referrer: referrer,
        post_url: discussion.url,
        post_modified_at: discussion.updated_at,
        type: 'forum-post',
        text: discussion.comments.first.text,
        created_at: discussion.created_at,
        author: discussion.poster&.name,
        author_email: discussion.poster&.email,
        languages: Rails.application.config.available_locales.keys,
        env: {},
      },
    ]

    is_spam, is_blatant = Akismet.check(*akismet_params)

    AkismetSubmission.create!(item: discussion, akismet_params: akismet_params, result_spam: is_spam, result_blatant: is_blatant)

    return unless is_spam

    discussion.update(review_reason: 'akismet')
    Report.create!(item: discussion.comments.first, auto_reporter: 'akismet', reason: Report::REASON_SPAM)
  end
end
