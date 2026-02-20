class ProxiedImageFetchJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log, lock_ttl: 15.minutes.to_i

  def perform(original_url)
    ProxiedImage.store(original_url)
  end
end
