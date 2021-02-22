class SessionsController < Devise::SessionsController
  BANNED_DELETE_PATH = '/users/banned_delete'.freeze

  include Devise::Controllers::Rememberable
  include LoginMethods
  include LocalizedRequest

  skip_before_action :verify_authenticity_token, only: [:omniauth_callback]

  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.banned?
      sign_out resource
      flash.delete(:notice) # get rid of "Signed in successfully."

      if session[:user_return_to] == BANNED_DELETE_PATH
        flash.delete(:alert)
        flash[:notice] = I18n.t('users.banned_delete.complete')
        resource.destroy!
        return root_path
      end

      moderator_action = ModeratorAction.order(id: :desc).find_by(user: resource)
      delete_link = new_user_session_path(return_to: BANNED_DELETE_PATH)
      flash[:html_safe] = true
      flash[:alert] = if moderator_action&.report
                        It.it('users.banned_notice.with_report', report_link: report_path(moderator_action.report), delete_link: delete_link)
                      elsif moderator_action&.reason.present?
                        It.it('users.banned_notice.with_reason', reason: moderator_action.reason, delete_link: delete_link)
                      else
                        It.it('users.banned_notice.no_report_no_reason', delete_link: delete_link)
                      end
      return root_path
    end
    return super(resource)
  end

  def omniauth_callback
    unless params[:failure].nil?
      handle_omniauth_failure
      return
    end

    unless params[:error].nil?
      handle_omniauth_failure(params[:error])
      return
    end

    o = request.env['omniauth.auth']
    if o.nil?
      handle_omniauth_failure
      return
    end

    return_to = clean_redirect_param(:origin)
    provider = o[:provider]
    uid = o[:uid]
    email = o[:info][:email]
    email = nil if !email.nil? && email.empty?
    if session[:chosen_name]
      # from name conflict
      name = session[:chosen_name]
      session.delete(:chosen_name)
      # don't go to omniauth.origin (the first sign in attempt), go to *its* omniauth.origin
      request.env['omniauth.origin'] = params[:origin]
    else
      name = o[:info][:nickname] || # GitHub
             (provider == 'browser_id' ? o[:info][:name].split('@').first : nil) || # Persona
             o[:info][:name] # Google
    end
    url = (o[:extra] && o[:extra][:raw_info] && o[:extra][:raw_info][:html_url]) || # GitHub
          (o[:extra] && o[:extra][:raw_info] && o[:extra][:raw_info][:profile]) # Google

    # does the identity already exist?
    identity = Identity.find_by(provider: provider, uid: uid)
    unless identity.nil?
      # existing user
      user = identity.user
      if !current_user.nil? && (user.id != current_user.id)
        # another user has this already!
        flash[:notice] = t('users.external_sign_in_already_used', provider: Identity.pretty_provider(provider), user_name: user.name)
        redirect_to return_to || request.env['omniauth.origin'] || after_sign_in_path_for(current_user)
        return
      end
      # update the existing user for syncing accounts
      if identity.syncing && ((user.name != name) || ((user.email != email) && !email.nil?))
        user.name = name
        user.email = email unless email.nil?
        # if we can't save (name already used?) that's ok, we just won't sync
        user.reload unless user.save
      end
      sign_in user
      remember_me user if session[:remember_me] || params[:remember_me]
      set_flash_message(:notice, :signed_in)
      redirect_to return_to || after_sign_in_path_for(user)
      return
    end

    # identity did not previously exist

    # user already logged in - add identity to their account
    unless current_user.nil?
      identity = Identity.new(provider: provider, uid: uid, syncing: false, url: url, user: current_user)
      unless identity.valid?
        handle_omniauth_failure(identity.errors.full_messages.join(', '))
        return
      end
      current_user.identities << identity
      current_user.save(validate: false)
      flash[:notice] = t('users.external_sign_in_added', provider: Identity.pretty_provider(provider))
      redirect_to return_to || request.env['omniauth.origin'] || after_sign_in_path_for(current_user)
      return
    end

    # does another user already have that e-mail?
    unless email.nil?
      @same_email_user = User.find_by(email: email)
      unless @same_email_user.nil?
        @provider = Identity.pretty_provider(provider)
        @email = email
        render 'omniauth_callback_same_email'
        return
      end
    end

    # we need to create a user, but the provider didn't provide an email
    if email.nil?
      @provider = Identity.pretty_provider(provider)
      render 'omniauth_callback_no_email'
      return
    end

    # does another user already have that name?
    same_name_user = User.find_by(name: name)
    unless same_name_user.nil?
      @provider = provider
      @name = name
      render 'omniauth_callback_same_name'
      return
    end

    # create a new user
    identity = Identity.new(provider: provider, uid: uid, syncing: true, url: url)
    user = User.new(name: name, email: email, locale_id: session[:locale_id], identities: [identity])
    identity.user = user
    unless user.save
      handle_omniauth_failure(user.errors.full_messages.join(', '))
      return
    end
    sign_in user
    remember_me user if session[:remember_me] || params[:remember_me]
    flash[:notice] = t('users.external_sign_in_confirmation', site_name: site_name, provider: identity.pretty_provider, username: user.name)
    redirect_to return_to || after_sign_in_path_for(user)
  end

  def omniauth_failure
    handle_omniauth_failure(params[:message])
  end

  # https://github.com/plataformatec/devise/issues/4084
  def require_no_authentication
    set_locale
    super unless performed?
  end

  def new
    @bots = 'noindex'
    super
  end

  # Prevent session termination vulnerability
  # https://makandracards.com/makandra/53562-devise-invalidating-all-sessions-for-a-user
  def destroy
    current_user&.invalidate_all_sessions!
    super
  end

  private

  def handle_omniauth_failure(error = 'unknown')
    flash[:notice] = t('users.external_sign_in_failed', provider: Identity.pretty_provider(params[:provider] || params[:strategy]), error: error)
    redirect_to clean_redirect_param(:origin) || request.env['omniauth.origin'] || new_user_session_path
  end

  protected

  def clean_redirect_param(param_name)
    v = params[param_name]
    # don't redirect to a failure path
    return nil if v.nil? || v.include?('failure')

    return super(param_name)
  end
end
