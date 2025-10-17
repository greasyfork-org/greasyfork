class SpammyEmailDomainBannerJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  OLD_USER_CUT_OFF = 1.month
  MINIMUM_USER_COUNT = 4
  BLOCKED_USER_THRESHOLD = 0.75
  REBLOCKED_MULTIPLIER = 2

  def perform(domain)
    # If we're already blocked, don't block.
    sed = SpammyEmailDomain.find_for_domain(domain)
    return if sed&.active?

    users = User.where(email_domain: domain)

    # If it was never previously banned, and users existed for a while, don't auto-ban.
    return if !sed&.expires_at && users.not_banned.where(created_at: ..OLD_USER_CUT_OFF.ago).any?

    users_count = users.count
    return if users_count < MINIMUM_USER_COUNT

    banned_users_count = users.banned.count
    return if banned_users_count.to_r / users_count < BLOCKED_USER_THRESHOLD

    if sed
      sed.block_count += 1
    else
      sed = SpammyEmailDomain.new(domain:, block_type: SpammyEmailDomain::BLOCK_TYPE_REGISTER, block_count: 1)
    end

    sed.expires_at = (REBLOCKED_MULTIPLIER ^ (sed.block_count - 1)).months.from_now
    sed.save!

    SpammyEmailDomainBannerMailer.banned_confirm(domain, sed.expires_at).deliver_later
  end
end
