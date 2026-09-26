class InactiveUserMailer < ApplicationMailer
  def notify(user)
    set_locale_for_user(user)
    @user = user
    mail(to: @user.email, subject: I18n.t('mailers.inactive_user.subject'))
  end
end
