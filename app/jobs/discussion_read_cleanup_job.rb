class DiscussionReadCleanupJob < ApplicationJob
  queue_as :low

  def perform
    DiscussionRead
      .joins(:user)
      .where.not(users: { discussions_read_since: nil })
      .where('discussion_reads.read_at <= users.discussions_read_since')
      .delete_all

    self.class.set(wait: 1.hour).perform_later unless Rails.env.test?
  end
end
