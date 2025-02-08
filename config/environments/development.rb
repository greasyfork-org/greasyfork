Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :redis_cache_store, { url: 'redis://localhost:6379/0', expires_in: 2.hours }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}",
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.active_storage.service = :aws

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  config.active_support.deprecation = :raise

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  routes.default_url_options[:host] = 'greasyfork.local'
  routes.default_url_options[:protocol] = 'http'

  config.enable_detect_locale = true
  config.log_cache_misses = true

  config.active_job.queue_adapter = :inline

  config.hosts += %w[greasyfork.local update.greasyfork.local api.greasyfork.local test.greasyfork.org sleazyfork.local update.sleazyfork.local api.greasyfork.local test.sleazyfork.org cn-greasyfork.local update.cn-greasyfork.local api.cn-greasyfork.local]
end
