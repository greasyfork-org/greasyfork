# https://github.com/rack/rack-attack/issues/210#issuecomment-786859918
module RackAttackThrottleExceeded
  def exceeded?(request)
    discriminator = discriminator_for(request)
    return false unless discriminator

    current_period = period_for(request)
    current_limit = limit_for(request)

    key = [Time.now.to_i / current_period, name, discriminator].join(':')
    count = cache.read(key).to_i

    count > current_limit
  end
end

Rack::Attack::Throttle.include(RackAttackThrottleExceeded)

SIGNUP_PATH_PATTERN = Regexp.new("\\A/(#{Rails.application.config.available_locales.keys.map { |locale| Regexp.escape(locale) }.join('|')})/users\\z")
LOGIN_PATH_PATTERN = Regexp.new("\\A/(#{Rails.application.config.available_locales.keys.map { |locale| Regexp.escape(locale) }.join('|')})/users/sign_in\\z")

PENTESTER_QUERY_STRINGS = [
  '/etc/passwd',
  'bxss.me',
  'gethostbyname',
].freeze

if Rails.env.production?
  if Rails.application.config.ip_address_tracking
    Rack::Attack.throttle('limit registrations per ip', limit: 3, period: 3600) do |req|
      req.ip if SIGNUP_PATH_PATTERN.match?(req.path) && req.post?
    end
  end

  if Rails.application.config.ip_address_tracking
    Rack::Attack.throttle('limit registrations per email domain', limit: 3, period: 3600) do |req|
      req.ip if SIGNUP_PATH_PATTERN.match?(req.path) && req.post? && req.params.dig('user', 'email')&.ends_with?('163.com')
    end
  end

  Rack::Attack.throttle('limit logins attempts per email', limit: 10, period: 600) do |req|
    req.params.dig('user', 'email') if LOGIN_PATH_PATTERN.match?(req.path) && req.post? && req.params.dig('user', 'email')
  end

  if Rails.application.config.ip_address_tracking
    Rack::Attack.throttle('limit logins attempts per ip', limit: 10, period: 3600) do |req|
      req.ip if LOGIN_PATH_PATTERN.match?(req.path) && req.post? && req.params.dig('user', 'email')
    end
  end

  if Rails.application.config.ip_address_tracking
    Rack::Attack.blocklist('fail2ban pentesters') do |req|
      Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 5.minutes) do
        qs = CGI.unescape(req.query_string)
        PENTESTER_QUERY_STRINGS.any? { |pentester_qs| qs.include?(pentester_qs) }
      end
    end
  end

  if Rails.application.config.ip_address_tracking
    Rack::Attack.throttle('super-installers', limit: 3, period: 60) do |req|
      req.ip if req.post? && req.path.include?('install-ping')
    end
  end

  if Rails.application.config.ip_address_tracking
    Rack::Attack.throttle('super-feedbackers', limit: 5, period: 10.seconds) do |req|
      req.ip if req.path.ends_with?('/feedback') || req.path.ends_with?('/stats')
    end
  end

  if Rails.application.config.ip_address_tracking
    Rack::Attack.throttle('super-discussionners', limit: 5, period: 10.seconds) do |req|
      req.ip if req.path == '/en/discussions'
    end
  end

  if Rails.application.config.ip_address_tracking
    # If you exceed any of the specified throttles and then make another request, go to the penalty box. Requests while
    # in the penalty box don't count, so you'll be back after the ban is over.
    THROTTLE_BANNER_THROTTLE_NAMES = %w[super-discussionners super-feedbackers].freeze
    Rack::Attack.blocklist('throttle-banner') do |req|
      # maxretry - how many requests after the throttle before they get banned
      # findtime - how far back should we look for requests for maxretry
      # bantime - how long to ban
      Rack::Attack::Fail2Ban.filter("throttled/#{req.ip}", maxretry: 0, findtime: 1.second, bantime: 1.minute) do
        THROTTLE_BANNER_THROTTLE_NAMES.any? { |name| Rack::Attack.throttles[name]&.exceeded?(req) }
      end
    end
  end
end

ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
  Rails.logger.warn("#{payload[:request].env['rack.attack.matched']} - #{payload[:request].ip}")
end
