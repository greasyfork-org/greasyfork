require 'net/http'
require 'uri'

class ScriptChecking::LinkChecker
  REDIRECT_PATTERNS = [
    /https?:\/\/bit\.ly\/[a-z0-9]+/i
  ]

  class << self
    def check(script_version)
      blocked_urls = BlockedScriptUrl.all
      code = script_version.code

      blocked_urls.each do |bu|
        return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BAN, bu.public_reason, bu.private_reason, bu) if code.include?(bu.url)
      end

      redirect_destinations = code.scan(Regexp.union(*REDIRECT_PATTERNS)).uniq.map { |url| resolve(url) }.compact.uniq

      blocked_urls.each do |bu|
        return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BAN, bu.public_reason, bu.private_reason, bu) if redirect_destinations.include?(bu.url)
      end

      return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_OK)
    end

    def resolve(url, remaining_tries: 5)
      res = Net::HTTP.get_response(URI(url))
      return url if res['location'].nil? || remaining_tries == 0
      resolve(res['location'], remaining_tries: remaining_tries - 1)
    end
  end
end