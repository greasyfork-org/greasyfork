class ConsecutiveBadRatingsMailer < ApplicationMailer
  def notify(script, user, locale)
    set_locale(locale)
    script_name = script.name(locale)
    mail(to: user.email, subject: t('mailers.consecutive_bad_ratings.notify.subject', site_name: 'Greasy Fork', script_name:)) do |format|
      format.text do
        t('mailers.consecutive_bad_ratings.notify.text',
          site_name: 'Greasy Fork',
          script_name:,
          script_url: script_url(script, locale:),
          feedback_url: feedback_script_url(script, locale:),
          delete_date: l(script.consecutive_bad_ratings_at.to_date + Script::CONSECUTIVE_BAD_RATINGS_GRACE_PERIOD, format: :short, locale:))
      end
    end
  end
end
