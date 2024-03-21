class CommentSpamCheckJob < ApplicationJob
  queue_as :low

  def perform(comment, ip, user_agent, referrer)
    return if comment.soft_deleted?

    return if pattern_check(comment)

    return if repeat_check(comment)

    check_with_akismet(comment, ip, user_agent, referrer)
  end

  def pattern_check(comment)
    return false unless ['gmkm.zrnq.one', '🐧'].any? { |s| comment.text.include?(s) }

    discussion.update(review_reason: Discussion::REVIEW_REASON_RAINMAN)
    Report.create!(item: discussion, auto_reporter: 'rainman', reason: Report::REASON_SPAM)
  end

  def repeat_check(comment)
    return false unless comment.poster.created_at > 7.days.ago

    Report.create!(item: comment, auto_reporter: 'rainman', reason: Report::REASON_SPAM) if comment.poster.comments.where('id < ?', comment.id).where(text: comment.text).any?
  end

  def check_with_akismet(comment, ip, user_agent, referrer)
    return unless Akismet.api_key

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

    return unless is_spam

    Report.create!(item: comment, auto_reporter: 'akismet', reason: Report::REASON_SPAM)
    comment.update(review_reason: Discussion::REVIEW_REASON_AKISMET)
  end
end
