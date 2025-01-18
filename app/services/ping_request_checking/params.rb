require 'user_agent_parser'

module PingRequestChecking
  PREFIX = '4'.freeze

  class Params
    def self.check(request)
      return false unless request.params['mo']

      now = DateTime.now
      return true if Digest::SHA1.hexdigest(PREFIX + now.utc.strftime('%Y%-m%-d%-H')) == request.params['mo']

      return Digest::SHA1.hexdigest(PREFIX + (now - 1.hour).utc.strftime('%Y%-m%-d%-H')) == request.params['mo']
    end
  end
end
