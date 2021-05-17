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

  Rack::Attack.throttle('limit logins attempts per email', limit: 20, period: 300) do |req|
    req.params.dig('user', 'email') if LOGIN_PATH_PATTERN.match?(req.path) && req.post? && req.params.dig('user', 'email')
  end

  if Rails.application.config.ip_address_tracking
    Rack::Attack.throttle('limit logins attempts per ip', limit: 20, period: 3600) do |req|
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
end

ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
  Rails.logger.warn("#{payload[:request].env['rack.attack.matched']} - #{payload[:request].ip}")
end
