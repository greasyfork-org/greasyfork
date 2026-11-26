require 'omniauth'

module SafeOmniauthOrigin
  MAX_ORIGIN_SIZE = 128

  def store_origin
    super
    origin = session['omniauth.origin']
    return unless origin && origin.to_json.bytesize > MAX_ORIGIN_SIZE

    session.delete('omniauth.origin')
    log :warn, "Discarding oversized authentication origin (#{origin.bytesize} bytes)"
  end
end

OmniAuth::Strategy.prepend SafeOmniauthOrigin
OmniAuth.config.max_remembered_params_bytesize = 64

Rails.application.config.middleware.use OmniAuth::Builder do
  # https://github.com/settings/applications
  provider :github, Rails.application.credentials.github_login[:key], Rails.application.credentials.github_login[:secret], scope: 'read:user,user:email'
  # https://gitlab.com/oauth/applications/116475
  provider :gitlab, Rails.application.credentials.gitlab_login[:key], Rails.application.credentials.gitlab_login[:secret], scope: 'read_user'
  # https://console.developers.google.com/project/916907882575/apiui/credential?authuser=0
  provider :google_oauth2, Rails.application.credentials.google_login[:key], Rails.application.credentials.google_login[:secret]
end
Rails.application.config.available_auths = {
  'github' => 'GitHub',
  'gitlab' => 'GitLab',
  'google_oauth2' => 'Google',
}
OmniAuth.config.on_failure = proc do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

OmniAuth.config.before_request_phase = lambda { |env|
  p = Rack::Request.new(env).params
  session = env['rack.session']
  return_to = session[:user_return_to]
  if return_to && return_to.bytesize > SafeStoreLocation::MAX_LOCATION_SIZE
    session.delete(:user_return_to)
    Rails.logger.warn("Discarding oversized sign-in return location (#{return_to.bytesize} bytes)")
  end

  validators = {
    'remember_me' => ->(value) { %w[0 1].include?(value) },
    'chosen_name' => ->(value) { value.length <= 50 },
    'locale_id' => ->(value) { /\A[0-9]{1,6}\z/.match?(value) },
    'return_to' => ->(value) { value.to_json.bytesize <= SafeStoreLocation::MAX_LOCATION_SIZE },
    'origin' => ->(value) { value.to_json.bytesize <= SafeOmniauthOrigin::MAX_ORIGIN_SIZE },
  }

  session['omniauth.params'] = session['omniauth.params'].select do |key, value|
    valid = validators.key?(key) && value.is_a?(String) && validators.fetch(key).call(value)
    Rails.logger.warn('Discarding unrecognized or invalid authentication parameter') unless valid
    valid
  end
  # OmniAuth can retain several sign-ins, and the app stores the fields it needs separately.
  while session['omniauth.params'].sum { |key, value| key.bytesize + value.bytesize } > OmniAuth.config.max_remembered_params_bytesize ||
        session['omniauth.params'].to_json.bytesize > 128
    key, = session['omniauth.params'].max_by { |name, value| name.to_json.bytesize + value.to_json.bytesize }
    session['omniauth.params'].delete(key)
    Rails.logger.warn("Discarding authentication parameter to limit session size: #{key}")
  end

  [:remember_me, :chosen_name, :locale_id].each do |key|
    value = p[key.to_s]
    if !value.nil? && (!value.is_a?(String) || !validators.fetch(key.to_s).call(value))
      Rails.logger.warn("Rejecting oversized or invalid authentication parameter: #{key}")
      raise ArgumentError, "Invalid authentication parameter: #{key}"
    end
    session[key] = value
  end
}

OmniAuth.config.after_request_phase = lambda { |env|
  session = env['rack.session']
  sign_ins = session['omniauth.sign_ins']
  # OAuth2 has already kept this request's params with its state.
  session.delete('omniauth.params') if sign_ins.is_a?(Hash) && sign_ins.key?(session['omniauth.state'])
}

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.allowed_hosts = Rails.application.config.hosts.select { |h| h.is_a?(String) && h.count('.') == 1 }

OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
