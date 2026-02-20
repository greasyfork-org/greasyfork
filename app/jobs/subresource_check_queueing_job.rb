class SubresourceCheckQueueingJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  def perform
    Subresource
      .with_integrity_hash_usages
      .where('last_attempt_at IS NULL or last_attempt_at < ?', 1.day.ago)
      .order(:last_attempt_at)
      .distinct
      .limit(50)
      .each do |subresource|
        SubresourceCheckJob.perform_later(subresource)
    end
  end
end
