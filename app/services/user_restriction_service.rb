class UserRestrictionService
  NEEDS_CONFIRMATION = :needs_confirmation
  BLOCKED = :blocked
  RATE_LIMITED = :rate_limited

  def initialize(user)
    @user = user
  end

  def new_script_restriction
    if @user.email
      sed = SpammyEmailDomain.find_by(domain: @user.email.split('@').last)
      if sed
        return BLOCKED if sed.blocked_script_posting?
        return NEEDS_CONFIRMATION if @user.in_confirmation_period?
      end
    end

    return NEEDS_CONFIRMATION unless @user.confirmed? || @user.identities.any?

    return RATE_LIMITED if @user.created_at >= 1.hour.ago && @user.scripts.where('created_at >= ?', 1.hour.ago).count >= 3

    nil
  end

  def must_recaptcha?
    @user.needs_to_recaptcha?
  end
end
