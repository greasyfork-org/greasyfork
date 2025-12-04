require 'net/http'
require 'uri'
require 'google_safe_browsing'
require 'js_executor'

module ScriptChecking
  class LinkChecker
    class << self
      def check(script_version)
        result = scan_for_direct_url_references(script_version)
        return result if result

        redirect_urls = scan_for_redirect_urls(script_version)
        redirect_destinations = redirect_urls.filter_map { |url| resolve(url) }.to_set
        result = checked_for_blocked_urls(redirect_destinations)
        return result if result

        urls_from_execution = (JsExecutor.extract_urls(script_version.code) - redirect_urls).to_set
        result = checked_for_blocked_urls(urls_from_execution)
        return result if result

        redirect_urls_from_execution = urls_from_execution.grep(redirect_url_pattern)
        redirect_destinations_from_execution = redirect_urls_from_execution.filter_map { |url| resolve(url) }.to_set
        result = checked_for_blocked_urls(redirect_destinations_from_execution)
        return result if result

        google_blocked_urls = check_with_google_safe_browsing(redirect_urls + redirect_destinations + urls_from_execution + redirect_urls_from_execution + redirect_destinations_from_execution)
        return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BLOCK, 'Script contains URLs flagged by Google Safe Browsing.', "Google Safe Browsing blocked: #{google_blocked_urls}") if google_blocked_urls.any?

        ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_OK)
      end

      def checked_for_blocked_urls(urls)
        return nil if urls.empty?

        bsu = BlockedScriptUrl.find_by(url: urls.map { |u| u.sub(/[?#&].*/, '') }.to_a) || BlockedScriptUrl.where(prefix: true).find { |b| urls.any? { |url| url.starts_with?(b.url) } }
        return nil if bsu.nil?

        return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BAN, bsu.public_reason, bsu.private_reason, bsu)
      end

      def scan_for_direct_url_references(script_version)
        attributes_to_check(script_version).each do |thing_to_check|
          BlockedScriptUrl.find_each do |bu|
            return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_BAN, bu.public_reason, bu.private_reason, bu) if thing_to_check.include?(bu.url)
          end
        end
        nil
      end

      def scan_for_redirect_urls(script_version)
        attributes_to_check(script_version).filter_map { |thing_to_check| thing_to_check.scan(redirect_url_pattern) }.flatten.to_set
      end

      def attributes_to_check(script_version)
        ([script_version.code] + script_version.active_localized_attributes.select { |aa| aa.attribute_key == 'additional_info' }.map(&:attribute_value)).compact
      end

      def redirect_url_pattern
        Regexp.union([
                       Regexp.new(%r{https?://}i.to_s + Regexp.union(*RedirectServiceDomain.pluck(:domain)).to_s + %r{/[a-z0-9-]+}i.to_s),
                       %r{https?://www\.baidu\.com/link\?url=[0-9a-z\-&=_]+}i,
                     ])
      end

      def resolve(url, remaining_tries: 5)
        return url if remaining_tries == 0

        begin
          res = Net::HTTP.get_response(URI(url))
        rescue Errno::ECONNREFUSED, URI::InvalidURIError, Socket::ResolutionError, Net::OpenTimeout
          return url
        end

        begin
          return resolve(res['location'], remaining_tries: remaining_tries - 1) if res['location'].present?
        rescue ArgumentError
          # An invalid URI?
          return url
        end

        meta_refresh_url = find_meta_refresh(res) if res['content-type'] == 'text/html'

        meta_refresh_url || url
      end

      def check_with_google_safe_browsing(urls)
        GoogleSafeBrowsing.check(urls)
      end

      def find_meta_refresh(response)
        begin
          html_doc = Nokogiri::HTML(response.body)
        rescue StandardError
          return nil
        end

        meta_refresh = html_doc.at_css('meta[http-equiv="refresh"]')&.attr('content')
        return nil unless meta_refresh

        _seconds, url = meta_refresh.split(';', 2)
        return nil unless url

        url.sub(/\AURL=/i, '').delete_prefix("'").delete_suffix("'")
      end
    end
  end
end
