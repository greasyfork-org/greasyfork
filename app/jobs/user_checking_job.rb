class UserCheckingJob < ApplicationJob
  queue_as :low

  discard_on ActiveJob::DeserializationError

  def perform(user)
    user.ban!(moderator: User.administrators.first, reason: 'Spam', delete_comments: true, delete_scripts: true) if bannable?(user)
  end

  def bannable?(user)
    return true if BlockedUser.any? { |bu| Regexp.new(bu.pattern).match?(user.name) }
    return true if user.email_domain == '163.com' && "#{user.name}@#{user.email_domain}" == user.email && /^[a-z]{3,5}[0-9]{3,5}$/.match?(user.name)
    return true if user.email_domain == 'qq.com' && repeating?(user.email.split('@').first)
  end

  def repeating?(text)
    text.length == 9 && text[0..2] == text[3..5] && text[6..8]
  end
end
