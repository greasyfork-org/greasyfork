class ApplicationMailer < ActionMailer::Base
  default from: 'Greasy Fork <noreply@greasyfork.org>'
  layout 'mailer'

  def unsubscribe_for_user(user)
    # Assuming set_locale was called first
    @unsubscribe_url = notifications_user_url(user, locale: I18n.locale)
    headers['List-Unsubscribe'] = "<#{one_click_unsubscribe_url(token: user.generate_token_for(:one_click_unsubscribe))}>"
    headers['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click'
  end

  def set_locale(locale)
    I18n.locale = @locale = locale
  end

  def set_locale_for_user(user, backup_locale: nil)
    set_locale(UserEmailService.locale_for(user, backup_locale:))
  end
end
