class AkismetCheckingJob < ApplicationJob
  queue_as :low

  def perform(discussion, ip, user_agent, referrer)
    return unless Akismet.api_key

    is_spam, is_blatant = Akismet.check(ip, user_agent, {
                                          referrer: referrer,
                                          post_url: discussion.url,
                                          post_modified_at: discussion.updated_at,
                                          type: 'forum-post',
                                          text: discussion.comments.first.text,
                                          created_at: discussion.created_at,
                                          author: discussion.poster.name,
                                          author_email: discussion.poster.email,
                                          languages: Rails.application.config.available_locales.keys,
                                          env: {},
                                        })
    discussion.akismet_spam = is_spam
    discussion.akismet_blatant = is_blatant
    discussion.review_reason = 'akismet' if is_spam
    discussion.save!
    Report.create!(item: discussion, auto_reporter: 'akismet', reason: Report::REASON_SPAM) if is_spam
  end
end
