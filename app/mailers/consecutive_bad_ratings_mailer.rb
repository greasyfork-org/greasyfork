class ConsecutiveBadRatingsMailer < ApplicationMailer
  def notify(script)
    script.users.each do |user|
      locale = (user.locale || script.locale)&.code || :en
      script_name = script.name(locale)
      mail(to: user.email, subject: t('mailers.consecutive_bad_ratings.notify.subject', locale: locale, site_name: 'Greasy Fork', script_name: script_name)) do |format|
        format.text do
          t('mailers.consecutive_bad_ratings.notify.text',
            locale: locale,
            site_name: 'Greasy Fork',
            script_name: script_name,
            script_url: script_url(script, locale: locale),
            feedback_url: feedback_script_url(script, locale: locale),
            delete_date: l(script.consecutive_bad_ratings_at.to_date + Script::CONSECUTIVE_BAD_RATINGS_GRACE_PERIOD, format: :short, locale: locale))
        end
      end
    end
  end
end
