require 'application_system_test_case'

class LocalesTest < ApplicationSystemTestCase
  test 'home page works in all locales' do
    Rails.application.config.available_locales.keys.each do |locale|
      ensure_locale_exists(locale)
      visit root_url(locale:)
    end
  end

  test 'script list works in all locales' do
    stub_es(Script)
    Rails.application.config.available_locales.keys.each do |locale|
      ensure_locale_exists(locale)
      visit scripts_url(locale:)
    end
  end

  test 'script show works in all locales' do
    script = scripts(:one)
    Rails.application.config.available_locales.keys.each do |locale|
      ensure_locale_exists(locale)
      visit script_url(script, locale:)
    end
  end

  def ensure_locale_exists(locale)
    Locale.find_or_create_by!(code: locale) do |l|
      l.english_name = 'Name'
      l.ui_available = true
    end
  end
end
