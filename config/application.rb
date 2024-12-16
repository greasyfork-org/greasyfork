require_relative 'boot'

# require 'rails/all'
[
  'active_record/railtie',
  'active_storage/engine',
  'action_controller/railtie',
  'action_view/railtie',
  'action_mailer/railtie',
  'active_job/railtie',
  # 'action_cable/engine',
  # 'action_mailbox/engine',
  'action_text/engine',
  'rails/test_unit/railtie',
  # 'sprockets/railtie',
].each do |railtie|
  require railtie
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Greasyfork
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets capistrano tasks])

    config.active_storage.variant_processor = :vips

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Overridden in config/initializers/omniauth.rb
    config.available_auths = {}

    config.active_record.observers = :script_observer

    config.exceptions_app = routes

    config.ip_address_tracking = true

    config.active_support.to_time_preserves_timezone = :zone
  end
end

ApplicationSettings = YAML.load_file(Rails.root.join('config/application.yml')) if Rails.root.join('config/application.yml').exist?
