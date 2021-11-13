Sentry.init do |config|
  config.dsn = Rails.application.secrets.sentry_api_key
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.excluded_exceptions += ['JSON::ParserError']
end
