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
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Overridden in config/initializers/omniauth.rb
    config.available_auths = {}

    config.active_record.observers = :script_observer

    config.active_record.schema_format = :sql

    config.exceptions_app = routes

    config.active_storage.replace_on_assign_to_many = false
    config.active_storage.variable_content_types << 'image/webp'

    config.ip_address_tracking = true
  end
end

ApplicationSettings = YAML.load_file(Rails.root.join('config/application.yml')) if Rails.root.join('config/application.yml').exist?
