require 'user_agent_parser'

module PingRequestChecking
  class Params
    def self.check(request)
      request.params['mo'] == '3'
    end
  end
end
