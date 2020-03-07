Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://192.168.149.153:6379/0' }
end if Rails.env.production?
