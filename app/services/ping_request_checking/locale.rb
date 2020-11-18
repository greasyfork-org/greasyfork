require 'user_agent_parser'

module PingRequestChecking
  class Locale
    def self.check(request)
      request.params['locale'].nil?
    end
  end
end
