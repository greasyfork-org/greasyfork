class AkismetSubmissionDeleteJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  KEEP_AGE = 1.year

  def perform
    AkismetSubmission.where(created_at: ...KEEP_AGE.ago).in_batches.delete_all
  end
end
