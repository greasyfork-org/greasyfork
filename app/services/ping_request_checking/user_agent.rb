require 'user_agent_parser'

module PingRequestChecking
  class UserAgent
    def self.check(request)
      user_agent = UserAgentParser.parse(request.user_agent)

      case user_agent.family
      when 'Chrome'
        user_agent.version.major && user_agent.version.major.to_i >= 80
      when 'axios', 'IE'
        false
      else
        true
      end
    end
  end
end
