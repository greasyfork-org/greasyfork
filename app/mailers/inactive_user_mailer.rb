require 'net/smtp'

class InactiveUserMailer < ApplicationMailer
  rescue_from Net::SMTPSyntaxError, Net::SMTPFatalError do |exception|
    Rails.logger.error("InactiveUserMailer delivery failed: #{exception.message}")
    nil
  end

  def notify(user)
    set_locale_for_user(user)
    @user = user
    mail(to: @user.email, subject: I18n.t('mailers.inactive_user.subject'))
  end
end
