class ScriptDeleteJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log, lock_ttl: 15.minutes.to_i

  PERMANENT_DELETION_DELAY = 7.days

  def perform
    Script.where.not(permanent_deletion_request_date: nil).where(permanent_deletion_request_date: ...PERMANENT_DELETION_DELAY.ago).find_each(&:destroy)
    Script.where(locked: true).where.not(delete_type: nil).where(deleted_at: ...1.year.ago).limit(100).each(&:destroy)
  end
end
