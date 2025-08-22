class AcceptInvitationService
  attr_accessor :error

  def initialize(script, user)
    @script = script
    @user = user
  end

  def invitation
    return @invitation if defined?(@invitation)

    @invitation = @script.script_invitations.order(expires_at: :desc).find_by(invited_user_id: @user.id)
  end

  def valid?
    @error = nil

    if @script.users.include?(@user)
      @error = 'scripts.invitations.current_user_already_author'
      return false
    end

    unless invitation
      @error = 'scripts.invitations.invitation_not_found'
      return false
    end

    if invitation.expired?
      @error = 'scripts.invitations.invitation_expired'
      return false
    end

    true
  end

  delegate :accept!, to: :invitation
end
