Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://192.168.149.153:6379/0' }
end if Rails.env.production?

Sidekiq.configure_server do |config|
  config.on(:startup) do
    BackgroundJob.perform_later if Sidekiq::Queue.new('background').none? { |sq| sq.item['wrapped'] == 'BackgroundJob' } &&
        Sidekiq::Workers.new.none? {|process_id, thread_id, work| work['payload']['wrapped'] == 'BackgroundJob' }
  end
end if Rails.env.production?
