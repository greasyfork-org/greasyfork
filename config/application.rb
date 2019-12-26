require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Greasyfork
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

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

    config.syntax_highlighting_limit = 500.kilobytes

    config.screenshot_max_count = 5
    config.screenshot_max_size = 200.kilobytes

    Mime::Type.register "application/javascript", :jsonp

    # Overridden in config/initializers/omniauth.rb
    config.available_auths = {}

    config.active_job.queue_adapter = :delayed_job
    
    config.active_record.belongs_to_required_by_default = true
    config.action_controller.per_form_csrf_tokens = true
    config.action_controller.forgery_protection_origin_check = true

    config.active_record.observers = :script_observer

    config.promoted_script_divisor = 1
  end
end
