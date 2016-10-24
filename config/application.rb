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

    config.active_record.schema_format = :sql

    I18n.config.enforce_available_locales = true
    # locales good enough to link to
    # names from https://api.drupal.org/api/drupal/includes!iso.inc/function/_locale_get_predefined_list/7
    config.available_locales = {'ar' => 'العَرَبِيةُ', 'bg' => 'Български', 'cs' => 'Čeština', 'da' => 'Dansk', 'de' => 'Deutsch', 'el' => 'Ελληνικά', 'en' => 'English', 'es' => 'Español', 'fi' => 'Suomi', 'fr' => 'Français', 'fr-CA' => 'Français canadien', 'hu' => 'Magyar', 'id' => 'Bahasa Indonesia', 'it' => 'Italiano', 'ja' => '日本語', 'ko' => '한국어', 'nb' => 'Bokmål',  'nl' => 'Nederlands', 'pl' => 'Polski', 'pt-BR' => 'Português do Brasil', 'ro' => 'Română', 'ru' => 'Русский', 'sk' => 'Slovenčina', 'sv' => 'Svenska', 'tr' => 'Türkçe', 'uk' => 'Українська', 'vi' => 'Tiếng Việt', 'zh-CN' => '简体中文', 'zh-TW' => '繁體中文'}
    config.help_translate_url = 'https://github.com/JasonBarnabe/greasyfork/wiki/Translating-Greasy-Fork'

    config.duplicate_check_size_limit = 100.kilobytes
    config.duplicate_check_line_threshold = 5

    config.syntax_highlighting_limit = 500.kilobytes

    config.screenshot_max_count = 5
    config.screenshot_max_size = 200.kilobytes

    Mime::Type.register "application/javascript", :jsonp

    # Overridden in config/initializers/omniauth.rb
    config.available_auths = {}

    config.active_job.queue_adapter = :delayed_job
    config.active_record.raise_in_transactional_callbacks = true
  end
end
