# frozen_string_literal: true

module Middleware
  class UserRequestLogger
    def initialize(app)
      @app = app
      @logger = Logger.new(Rails.root.join('log/custom_requests.log'))
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      if request.get? && request.params.key?('user')
        @logger.info(
          "URL=#{request.url} " \
          "X-Forwarded-For=#{env['HTTP_X_FORWARDED_FOR'].inspect} " \
          "IP=#{request.ip} " \
          "Remote-IP=#{request.remote_ip} " \
          "X-CF-Request=#{env['HTTP_X_CF_REQUEST_ID'].inspect} "
        )
      end

      @app.call(env)
    end
  end
end
