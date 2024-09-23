# Some helpers when sending notifications to potentially multiple users. These methods will handle creating the
# Notification objects and will `yield` for each user who should get an email.
class UserNotificationService
  def self.notify_users(users, item:, notification_type: nil, backup_locale: nil)
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

  def self.notify_authors(script, &)
    notify_users(script.users, item: script, backup_locale: script.locale, &)
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
                       .where(created_at: ...comment.created_at) # Notifications are delayed. We don't want to notify about anything that happened before they subscribed.
                       .includes(:user)
                       .map(&:user)
                       .uniq
    subscribed_users = subscribed_users.select(&:moderator?) if discussion.discussion_category.moderators_only?
    notify_users(subscribed_users, notification_type: Notification::NOTIFICATION_TYPE_NEW_COMMENT, item: comment, &)
    subscribed_users
  end

  def self.locale_for(user, backup_locale: nil)
    backup_locale = nil unless I18n.locale_available?(backup_locale&.code)
    user.available_locale_code || backup_locale&.code || :en
  end
end
