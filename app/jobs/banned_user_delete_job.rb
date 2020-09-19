class BannedUserDeleteJob < ApplicationJob
  queue_as :low

  BANNED_AGE = 6.months

  def perform
    # Can't do anything with Sphinx from within a Sidekiq job.
    did_something = false
    ThinkingSphinx::Callbacks.suspend do
      User.where('banned_at < ?', BANNED_AGE.ago).find_each do |user|
        user.destroy
        did_something ||= true
      end
    end
    SphinxReindexJob.perform_later if did_something
    self.class.set(wait: 1.hour).perform_later
  end
end
