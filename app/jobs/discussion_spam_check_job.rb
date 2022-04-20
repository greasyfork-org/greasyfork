class DiscussionSpamCheckJob < ApplicationJob
  queue_as :low

  def perform(discussion, ip, user_agent, referrer)
    return if discussion.soft_deleted?

    return if pattern_check(discussion)

    check_with_akismet(discussion, ip, user_agent, referrer)
  end

  def pattern_check(discussion)
    # WeChat spam
    return false unless discussion.first_comment.text.match?(/\p{Han}/) && discussion.first_comment.text.match?(/[0-9]{5,}\z/)

    discussion.update(review_reason: Discussion::REVIEW_REASON_RAINMAN)
    Report.create!(item: discussion, auto_reporter: 'rainman', reason: Report::REASON_SPAM)
  end

  def check_with_akismet(discussion, ip, user_agent, referrer)
    return unless Akismet.api_key

    akismet_params = [
      ip,
      user_agent,
      {
        referrer:,
        post_url: discussion.url,
        post_modified_at: discussion.updated_at,
        type: 'forum-post',
        text: discussion.first_comment.text,
        created_at: discussion.created_at,
        author: discussion.poster&.name,
        author_email: discussion.poster&.email,
        languages: Rails.application.config.available_locales.keys,
        env: {},
      },
    ]

    is_spam, is_blatant = Akismet.check(*akismet_params)

    AkismetSubmission.create!(item: discussion, akismet_params:, result_spam: is_spam, result_blatant: is_blatant)

    return unless is_spam

    Report.create!(item: discussion, auto_reporter: 'akismet', reason: Report::REASON_SPAM)
    discussion.update(review_reason: Discussion::REVIEW_REASON_AKISMET)
  end
end
