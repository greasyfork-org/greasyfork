# Some helpers when sending to potentially multiple users.
class UserEmailService
  def self.notify_users(users, user_filter: nil, backup_locale: nil)
    users = users.select { |u| user_filter.call(u) } if user_filter
    users.each do |user|
      yield user, locale_for(user, backup_locale:)
    end
  end

  def self.notify_authors(script, user_filter: nil, &)
    notify_users(script.users, user_filter:, backup_locale: script.locale, &)
  end

  def self.notify_authors_for_report(report, &)
    notify_users(report.item.users, user_filter: ->(u) { u.notify_as_reported }, backup_locale: report.item.locale, &)
  end

  def self.notify_reporter(report, &)
    notify_users([report.reporter].compact, user_filter: ->(u) { u.notify_as_reporter }, &)
  end

  def self.locale_for(user, backup_locale: nil)
    backup_locale = nil unless I18n.locale_available?(backup_locale&.code)
    user.available_locale_code || backup_locale&.code || :en
  end
end
