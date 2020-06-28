class UserFloodJob < ApplicationJob
  queue_as :low

  def perform
    most_used_domain = User
        .where.not(email: nil)
        .last(100)
        .pluck(:email)
        .map{ |email| email.split('@').last }
        .group_by { |domain| domain}
        .map { |domain, instances| [domain, instances.count] }
        .sort_by(&:last)
        .reverse
        .first
    if most_used_domain.last > 50
      ActionMailer::Base.mail(
          from: "noreply@greasyfork.org",
          to: "jason.barnabe@gmail.com",
          subject: "Greasy Fork registration flood",
          body: "#{most_used_domain.last} of the newest 100 users have the email domain #{most_used_domain.first}. https://greasyfork.org/en/users?email_domain=#{most_used_domain.first}"
      ).deliver
    end
    self.class.set(wait: 1.hour).perform_later
  end
end