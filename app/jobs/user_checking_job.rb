class UserCheckingJob < ApplicationJob
  queue_as :low

  discard_on ActiveJob::DeserializationError

  def perform(user)
    user.ban!(moderator: User.administrators.first, reason: 'Spam', delete_comments: true, delete_scripts: true) if user.name.include?('CX D K 58') || (user.email_domain == '163.com' && "#{user.name}@#{user.email_domain}" == user.email && /^[a-z]{3,5}[0-9]{3,5}$/.match?(user.name))
  end
end
