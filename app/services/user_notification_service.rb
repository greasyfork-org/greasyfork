# Some helpers when sending notifications to potentially multiple users. These methods will handle creating the
# Notification objects and will `yield` for each user who should get an email.
class UserNotificationService
  def self.notify_users(users, item:, notification_type:, backup_locale: nil)
    users
      .select { |u| notification_type.nil? || UserNotificationSetting.delivery_types_for_user(u, notification_type).include?(UserNotificationSetting::DELIVERY_TYPE_EMAIL) }
      .each do |user|
        yield user, locale_for(user, backup_locale:)
    end
    return unless notification_type

    users
      .select { |u| UserNotificationSetting.delivery_types_for_user(u, notification_type).include?(UserNotificationSetting::DELIVERY_TYPE_ON_SITE) }
      .each { |u| Notification.create!(notification_type:, user: u, item:) }
  end

  def self.notify_authors(script, notification_type:, &)
    notify_users(script.users, item: script, notification_type:, backup_locale: script.locale, &)
  end

  def self.notify_authors_for_report_filed(report, &)
    users = report.item.users
    notify_users(users, notification_type: Notification::NOTIFICATION_TYPE_REPORT_FILED_REPORTED, item: report, backup_locale: report.item.locale, &)
  end

  def self.notify_authors_for_report_resolved(report, &)
    users = report.item.users
    notify_users(users, notification_type: Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTED, item: report, backup_locale: report.item.locale, &)
  end

  def self.notify_reporter_for_report_rebutted(report, &)
    users = [report.reporter].compact
    notify_users(users, notification_type: Notification::NOTIFICATION_TYPE_REPORT_REBUTTED_REPORTER, item: report, &)
  end

  def self.notify_reporter_for_report_resolved(report, &)
    users = [report.reporter].compact
    notify_users(users, notification_type: Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTER, item: report, &)
  end

  # This also returns the list of users who are subscribed so that they can be exempted from further notifications.
  def self.notify_discussion_subscribed(comment, ignored_users: [], &)
    discussion = comment.discussion
    subscribed_users = discussion
                       .discussion_subscriptions
                       .where.not(user: ignored_users)

    # Notifications are delayed. We don't want to notify about anything that happened before they subscribed. However
    # in the case of a first comment on a script, the author can be auto-subscribed and this gets created slightly after
    # the comment, and we do want to notify in that case, so add a bit of padding.
    subscribed_before = (comment.first_comment? && comment.script) ? comment.created_at + 5.seconds : comment.created_at
    subscribed_users = subscribed_users.where(created_at: ...subscribed_before)

    subscribed_users = subscribed_users
                       .includes(:user)
                       .map(&:user)
                       .uniq
    subscribed_users = subscribed_users.select(&:moderator?) if discussion.discussion_category.moderators_only?
    notify_users(subscribed_users, notification_type: Notification::NOTIFICATION_TYPE_NEW_COMMENT, item: comment, &)
    subscribed_users
  end

  def self.notify_discussion_mention(comment, mentioned_users: [], &)
    notify_users(mentioned_users, notification_type: Notification::NOTIFICATION_TYPE_MENTION, item: comment, &)
  end

  def self.locale_for(user, backup_locale: nil)
    backup_locale = nil unless I18n.locale_available?(backup_locale&.code)
    user.available_locale_code || backup_locale&.code || :en
  end
end
