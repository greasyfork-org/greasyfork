require 'open-uri'
require 'ssrf_filter'
require 'timeout'

class PublicHttpFetcher
  class Error < StandardError; end
  class InvalidUrl < Error; end
  class FetchError < Error; end

  def self.get(url, read_timeout: 10, timeout: 11)
    uri = validate_url!(url)
    scheme_whitelist = (uri.scheme == 'https') ? ['https'] : %w[http https]

    response = Timeout.timeout(timeout) do
      SsrfFilter.get(
        uri.to_s,
        scheme_whitelist:,
        http_options: { read_timeout: }
      )
    end

    return response.body.to_s if response.code.to_i.between?(200, 299)

    raise OpenURI::HTTPError.new("#{response.code} #{response.message}", response)
  rescue SsrfFilter::Error => e
    raise FetchError, e.message
  end

  def self.validate_url!(url)
    uri = URI.parse(url)
    raise InvalidUrl, 'URL must be http or https' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    raise InvalidUrl, 'URL must have a host' unless uri.hostname

    uri
  rescue URI::InvalidURIError, TypeError
    raise InvalidUrl, 'URL must be http or https'
  end
end
