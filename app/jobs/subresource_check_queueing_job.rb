class SubresourceCheckQueueingJob < ApplicationJob
  queue_as :low

  def perform
    Subresource
      .with_integrity_hash_usages
      .where('last_attempt_at IS NULL or last_attempt_at < ?', 1.day.ago)
      .order(:last_attempt_at)
      .limit(50)
      .each do |subresource|
      SubresourceCheckJob.perform_later(subresource)
    end
  end
end
