Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://192.168.149.153:6379/0' }

  config.on(:startup) do
    [ScriptDuplicateCheckerQueueingJob, ScriptSyncQueueingJob].each do |klass|
      klass.perform_later if Sidekiq::Queue.new('background').none? { |sq| sq.item['wrapped'] == klass.name }
    end
  end
end if Rails.env.production?
