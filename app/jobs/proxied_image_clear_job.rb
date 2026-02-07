class ProxiedImageClearJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 15.minutes.to_i

  def perform
    ProxiedImage.expired.find_each(&:destroy)
  end
end
