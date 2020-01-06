require 'net/http'
require 'uri'

class ScriptChecking::LinkChecker
  class << self
    def check(script_version)
      blocked_urls = BlockedScriptUrl.all

      things_to_check = ([script_version.code] + script_version.active_localized_attributes.select { |aa| aa.attribute_key == 'additional_info'}.map(&:attribute_value)).compact

      redirect_service_pattern = Regexp.new(/https?:\/\//i.to_s + Regexp.union(*RedirectServiceDomain.pluck(:domain)).to_s + /\/[a-z0-9\-]+/i.to_s  )

      things_to_check.each do |thing_to_check|
        blocked_urls.each do |bu|
          return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BAN, bu.public_reason, bu.private_reason, bu) if thing_to_check.include?(bu.url)
        end

        redirect_destinations = thing_to_check.scan(redirect_service_pattern).uniq.map { |url| resolve(url) }.compact.uniq

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