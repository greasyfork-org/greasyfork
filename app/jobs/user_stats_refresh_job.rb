class UserStatsRefreshJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log

  sidekiq_retries_exhausted do |job, _exception|
    SidekiqUniqueJobs::Digests.new.delete_by_digest(job.fetch('lock_digest'))
  end

  BATCH_SIZE = 100
  BATCH_PAUSE = 1.second

  def perform
    User.where.associated(:authors).distinct.find_in_batches(batch_size: BATCH_SIZE) do |users|
      stats = UserScriptStats.for_users(users.map(&:id))
      users.each { |user| user.searchkick_script_stats = stats.fetch(user.id) }
      User.searchkick_index.reindex(users, mode: :inline)
      sleep BATCH_PAUSE
    end
  end
end
