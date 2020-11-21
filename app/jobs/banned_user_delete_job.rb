class BannedUserDeleteJob < ApplicationJob
  queue_as :low

  BANNED_AGE = 6.months

  def perform
    User.where('banned_at < ?', BANNED_AGE.ago).destroy_all
    self.class.set(wait: 1.hour).perform_later
  end
end
