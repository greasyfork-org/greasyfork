class UserFloodJob < ApplicationJob
  queue_as :low

  CHECK_COUNT = 100
  THRESHOLD = 25
  IGNORED_DOMAINS = %w[gmail.com qq.com].freeze

  def perform
    most_used_domain = User
                       .where.not(email: nil)
                       .not_banned
                       .last(CHECK_COUNT)
                       .pluck(:email)
                       .map { |email| email.split('@').last }
                       .group_by { |domain| domain }
                       .map { |domain, instances| [domain, instances.count] }
                       .max_by(&:last)

    if most_used_domain.last > THRESHOLD && IGNORED_DOMAINS.exclude?(most_used_domain.first)
      ActionMailer::Base.mail(
        from: 'noreply@greasyfork.org',
        to: 'jason.barnabe@gmail.com',
        subject: 'Greasy Fork registration flood',
        body: "#{most_used_domain.last} of the newest #{CHECK_COUNT} users have the email domain #{most_used_domain.first}. https://greasyfork.org/en/users?email_domain=#{most_used_domain.first}"
      ).deliver
    end
    self.class.set(wait: 1.hour).perform_later
  end
end
