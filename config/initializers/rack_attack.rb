SIGNUP_PATH_PATTERN = Regexp.new('\\A/(' + Rails.application.config.available_locales.keys.map { |locale| Regexp.escape(locale) }.join('|') + ')/users')

if Rails.env.production?
  Rack::Attack.throttle('limit registrations per ip', limit: 3, period: 3600) do |req|
    if SIGNUP_PATH_PATTERN.match?(req.path) && req.post?
      # Normalize the email, using the same logic as your authentication process, to
      # protect against rate limit bypasses.
      req.ip
    end
  end
end

ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
  Rails.logger.warn("#{payload[:request].env['rack.attack.matched']} - #{payload[:request].ip}")
end
