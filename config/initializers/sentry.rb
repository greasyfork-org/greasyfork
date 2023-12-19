Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_api_key
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.excluded_exceptions += ['JSON::ParserError', 'Sidekiq::JobRetry::Skip', 'Sidekiq::Shutdown', 'Puma::HttpParserError', 'ActionDispatch::RemoteIp::IpSpoofAttackError', 'Vips::Error', 'ActiveStorage::FileNotFoundError']
end
