class ApplicationMailer < ActionMailer::Base
  default from: 'Greasy Fork <noreply@greasyfork.org>'

  def unsubscribe_for_user(user)
    @unsubscribe_url = notifications_user_url(user, locale: user.available_locale_code)
    headers['List-Unsubscribe'] = "<#{@unsubscribe_url}>"
  end
end
