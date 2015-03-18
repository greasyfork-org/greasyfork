Greasyfork::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  #config.active_support.deprecation = :log
  config.active_support.deprecation = Proc.new { |message, callstack|
    raise NameError, message, callstack
  }

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  config.cache_store = :null_store
  #config.cache_store = :dalli_store, ['localhost:11211:10'], { :namespace => 'Greasy Fork', :expires_in => 1.hour, :compress => true }
  
  config.action_mailer.default_url_options = { :host => 'greasyfork.local' }

  routes.default_url_options[:host] = 'greasyfork.local'
  routes.default_url_options[:protocol] = 'http'
  
  config.verify_ownership_on_import = false
  config.userscriptsorg_host = 'http://userscripts.org:8080'
 
  config.enable_detect_locale = true
  config.download_locale_files = true

  config.log_cache_misses = true

  config.after_initialize do
    Bullet.enable = false
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.add_footer = true
  end
end
