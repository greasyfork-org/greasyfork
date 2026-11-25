class SoftDeletedForumContentDeleteJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log

  sidekiq_retries_exhausted do |job, _exception|
    SidekiqUniqueJobs::Digests.new.delete_by_digest(job.fetch('lock_digest'))
  end

  def perform
    cutoff = 1.year.ago
    Discussion.soft_deleted.where(deleted_at: ...cutoff).find_each(&:destroy!)
    # Destroying a first comment also destroys its discussion, so use the discussion's deletion time.
    Comment.soft_deleted.where(first_comment: false, deleted_at: ...cutoff).find_each(&:destroy!)
  end
end
