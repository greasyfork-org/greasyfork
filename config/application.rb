require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Greasyfork
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.i18n.enforce_available_locales = false
    config.active_record.schema_format = :sql

    # locales good enough to link to
    # names from https://api.drupal.org/api/drupal/includes!iso.inc/function/_locale_get_predefined_list/7
    config.available_locales = {'de' => 'Deutsch', 'en' => 'English', 'es' => 'Español', 'id' => 'Bahasa Indonesia', 'ja' => '日本語', 'nl' => 'Nederlands', 'pl' => 'Polski', 'ru' => 'Русский', 'zh-CN' => '简体中文', 'zh-TW' => '繁體中文'}
    config.help_translate_url = 'https://github.com/JasonBarnabe/greasyfork/wiki/Translating-Greasy-Fork'

    config.cpd_size_limit = 50.kilobytes
  end
end
