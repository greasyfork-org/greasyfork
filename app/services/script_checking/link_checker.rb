require 'net/http'
require 'uri'

class ScriptChecking::LinkChecker
  REDIRECT_PATTERNS = [
    /https?:\/\/bit\.ly\/[a-z0-9]+/i,
    /https?:\/\/bit\.do\/[a-z0-9\-]+/i,
  ]

  class << self
    def check(script_version)
      blocked_urls = BlockedScriptUrl.all

      things_to_check = ([script_version.code] + script_version.active_localized_attributes.select { |aa| aa.attribute_key == 'additional_info'}.map(&:attribute_value)).compact

      things_to_check.each do |thing_to_check|
        blocked_urls.each do |bu|
          return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BAN, bu.public_reason, bu.private_reason, bu) if thing_to_check.include?(bu.url)
        end

        redirect_destinations = thing_to_check.scan(Regexp.union(*REDIRECT_PATTERNS)).uniq.map { |url| resolve(url) }.compact.uniq

        blocked_urls.each do |bu|
          return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BAN, bu.public_reason, bu.private_reason, bu) if redirect_destinations.include?(bu.url)
        end
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