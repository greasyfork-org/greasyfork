# Some helpers when sending to potentially multiple users.
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

  def self.locale_for(user, backup_locale: nil)
    backup_locale = nil unless I18n.locale_available?(backup_locale&.code)
    user.available_locale_code || backup_locale&.code || :en
  end
end
