Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_api_key
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.excluded_exceptions += ['JSON::ParserError', 'Sidekiq::JobRetry::Skip', 'Sidekiq::Shutdown', 'Puma::HttpParserError', 'ActionDispatch::RemoteIp::IpSpoofAttackError', 'Vips::Error', 'ActiveStorage::FileNotFoundError']
  config.traces_sample_rate = 0.00001
  config.profiles_sample_rate = 0.00001
  config.metrics.enabled = true
end
