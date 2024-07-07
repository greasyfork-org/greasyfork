class UserRestrictionService
  NEEDS_CONFIRMATION = :needs_confirmation
  DELAYED = :delayed
  BLOCKED = :blocked
  RATE_LIMITED = :rate_limited

  NEW_USER_RATE_LIMITS = {
    1.hour => 3,
    1.day => 10,
    1.week => 20,
  }.freeze

  def initialize(user)
    @user = user
  end

  def new_script_restriction
    if @user.email
      sed = SpammyEmailDomain.find_by(domain: @user.email.split('@').last)
      if sed
        return BLOCKED if sed.blocked_script_posting?
        return DELAYED if @user.in_confirmation_period?
      end
    end

    return NEEDS_CONFIRMATION unless @user.confirmed_or_identidied?

    return RATE_LIMITED if new_user? && NEW_USER_RATE_LIMITS.any? { |period, script_count| @user.scripts.where(created_at: period.ago..).count >= script_count }

    nil
  end

  def must_recaptcha?
    @user.needs_to_recaptcha?
  end

  def new_user?
    @user.created_at >= 1.month.ago && @user.scripts.not_deleted.where(created_at: ..1.week.ago).none?
  end

  def allow_posting_profile?
    @user.confirmed_or_identidied? && (@user.scripts.not_deleted.any? || @user.comments.any?)
  end
end
