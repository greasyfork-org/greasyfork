Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_api_key
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.excluded_exceptions += ['JSON::ParserError', 'Sidekiq::JobRetry::Skip', 'Sidekiq::Shutdown', 'Puma::HttpParserError', 'ActionDispatch::RemoteIp::IpSpoofAttackError', 'ActiveStorage::FileNotFoundError']
  config.traces_sample_rate = 0.001
  config.profiles_sample_rate = 0.001
  config.metrics.enabled = true

  config.before_send = lambda do |event, hint|
    return nil if hint[:exception].message.include?('invalid byte sequence in UTF-8')

    event
  end
end
