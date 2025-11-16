require 'omniauth'

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
  [:remember_me, :chosen_name, :locale_id].each do |key|
    env['rack.session'][key] = p[key.to_s]
  end
}

OmniAuth.config.allowed_request_methods = [:post]
