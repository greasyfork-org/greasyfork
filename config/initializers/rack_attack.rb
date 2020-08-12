SIGNUP_PATH_PATTERN = Regexp.new("\\A/(#{Rails.application.config.available_locales.keys.map { |locale| Regexp.escape(locale) }.join('|')})/users\\z")

if Rails.env.production?
  Rack::Attack.throttle('limit registrations per ip', limit: 3, period: 3600) do |req|
    req.ip if SIGNUP_PATH_PATTERN.match?(req.path) && req.post?
  end

  Rack::Attack.throttle('limit registrations per email', limit: 10, period: 3600) do |req|
    req.ip if SIGNUP_PATH_PATTERN.match?(req.path) && req.post? && req.params.dig('user', 'email')&.ends_with?('163.com')
  end
end

ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
  Rails.logger.warn("#{payload[:request].env['rack.attack.matched']} - #{payload[:request].ip}")
end
