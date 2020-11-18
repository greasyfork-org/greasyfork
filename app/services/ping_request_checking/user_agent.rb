require 'user_agent_parser'

module PingRequestChecking
  class UserAgent
    def self.check(request)
      user_agent = UserAgentParser.parse(request.headers['User-Agent'])
      return user_agent.family != 'Chrome' || (user_agent.version.major && user_agent.version.major < 80)
    end
  end
end
