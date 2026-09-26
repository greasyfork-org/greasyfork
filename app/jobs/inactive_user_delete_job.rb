class InactiveUserDeleteJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  def perform
    User.inactive_deletable.destroy_all
  end
end
