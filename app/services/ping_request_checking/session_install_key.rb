require 'user_agent_parser'

module PingRequestChecking
  class SessionInstallKey
    SESSION_KEY = :install_keys

    def self.check(request)
      request.session[SESSION_KEY]&.include?(request.params[:id].to_i)
    end
  end
end
