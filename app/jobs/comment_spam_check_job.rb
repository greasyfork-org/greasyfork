class CommentSpamCheckJob < ApplicationJob
  queue_as :low

  def perform(comment, ip, user_agent, referrer)
    return if comment.soft_deleted?

    return if pattern_check(comment)

    if (report = repeat_check(comment))
      report.uphold!(moderator: User.administrators.first, moderator_notes: 'Blatant comment spam', ban_user: true, delete_comments: true, delete_scripts: true) if report.blatant
      return
    end

    check_with_akismet(comment, ip, user_agent, referrer)
  end

  def pattern_check(comment)
    return unless self.class.text_is_spammy?(comment.text)

    Report.create!(item: comment, auto_reporter: 'rainman', reason: Report::REASON_SPAM)
  end

  def repeat_check(comment)
    previous_comment = self.class.find_previous_comment(comment)
    if previous_comment
      previous_report = previous_comment.reports.upheld.take
      return Report.create!(item: comment, auto_reporter: 'rainman', reason: previous_report&.reason || Report::REASON_SPAM, blatant: self.class.blatant?(comment), explanation: "Repost of#{' deleted' if previous_comment.soft_deleted?} comment: #{previous_comment.url}. #{"Previous report: #{previous_report.url}" if previous_report}")
    end

    previous_comment = self.class.find_previous_comment_with_link(comment)
    return unless previous_comment

    previous_report = previous_comment.reports.upheld.take
    return Report.create!(item: comment, auto_reporter: 'rainman', reason: previous_report&.reason || Report::REASON_SPAM, blatant: self.class.blatant?(comment), explanation: "Repost of#{' deleted' if previous_comment.soft_deleted?} comment with same link: #{previous_comment.url}. #{"Previous report: #{previous_report.url}" if previous_report}")
  end

  def self.find_previous_comment(comment)
    return nil unless comment.poster.created_at > 7.days.ago

    comment.poster.comments.where(id: ...comment.id).find_by(text: comment.text) || Comment.where(id: ...comment.id).where(text: comment.text).find_by(deleted_at: 1.month.ago..)
  end

  def self.find_previous_comment_with_link(comment)
    return nil unless comment.poster.created_at > 7.days.ago

    links = extract_possibly_spammy_links(comment)
    return unless links.any?

    links.uniq!

    text_condition = links.map { |_link| 'text LIKE ?' }.join(' OR ')
    condition_params = links.map { |link| "%#{Comment.sanitize_sql_like(link)}%" }
    comment.poster.comments.where(id: ...comment.id).find_by(text_condition, *condition_params) || Comment.where(id: ...comment.id).where(text_condition, *condition_params).find_by(deleted_at: 1.month.ago..)
  end

  def self.find_recently_deleted_comment_count_with_link(comment)
    links = extract_possibly_spammy_links(comment)
    return 0 unless links.any?

    text_condition = links.map { |_link| 'text LIKE ?' }.join(' OR ')
    condition_params = links.map { |link| "%#{Comment.sanitize_sql_like(link)}%" }
    Comment.where(text_condition, *condition_params).where(deleted_at: (comment.created_at - 1.month)...comment.created_at).count
  end

  def self.extract_possibly_spammy_links(comment)
    Nokogiri::HTML(ApplicationController.helpers.format_user_text(comment.text, comment.text_markup)).css('a[href]').pluck('href').reject { |href| href.starts_with?('https://greasyfork.org/') || href.starts_with?('https://sleazyfork.org/') }
  end

  # Given that we've determined something is spam, is it also blatant?
  def self.blatant?(comment)
    # If there are multiple recently deleted comments with any of the same links.
    recent_deleted_comment_count = find_recently_deleted_comment_count_with_link(comment)
    return true if recent_deleted_comment_count >= 2

    # If there are more than 5 links in the post
    extract_possibly_spammy_links(comment).count >= 5
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

  def self.text_is_spammy?(text)
    [
      'yxd02040608',
      'zrnq',
      'gmkm.zrnq.one',
      '🐧',
      'CBD ',
      'Keto ',
      'hbyvipxnzj.buzz',
      'https://support.google.com/',
    ].any? { |s| text.include?(s) }
  end
end
