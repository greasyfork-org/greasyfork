class SpammyEmailDomainBannerMailer < ApplicationMailer
  def banned_confirm(domain, expires_at)
    mail(to: User.administrators.pluck(:email), subject: 'Email domain banned') do |format| # rubocop:disable Rails/I18nLocaleTexts
      format.text do
        render plain: "Email domain #{domain} banned until #{expires_at}."
      end
    end
  end
end
