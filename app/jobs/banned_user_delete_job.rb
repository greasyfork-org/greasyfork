class BannedUserDeleteJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  BANNED_AGE = 6.months

  def perform
    User.where(banned_at: ...BANNED_AGE.ago).destroy_all
  end
end
