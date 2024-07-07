class DiscussionReadCleanupJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log, lock_ttl: 15.minutes.to_i

  def perform
    DiscussionRead
      .joins(:user)
      .where.not(users: { discussions_read_since: nil })
      .where('discussion_reads.read_at <= users.discussions_read_since')
      .delete_all
  end
end
