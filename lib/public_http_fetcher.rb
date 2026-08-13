require 'open-uri'
require 'ssrf_filter'
require 'timeout'

class PublicHttpFetcher
  MAX_REDIRECTS = 64
  REDIRECT_CODES = [301, 302, 303, 307, 308].freeze

  def self.get(url, read_timeout: 10, timeout: 11)
    uri = parse_uri(url)

    Timeout.timeout(timeout) do
      redirects_remaining = MAX_REDIRECTS
      loop do
        response = SsrfFilter.get(
          uri.to_s,
          allow_unfollowed_redirects: true,
          max_redirects: 0,
          http_options: { read_timeout: },
        )
        status = response.code.to_i

        return response.body.to_s if status.between?(200, 299)
        raise_http_error(response) unless REDIRECT_CODES.include?(status) && response['location']
        raise OpenURI::TooManyRedirects.new('Too many redirects', response) if redirects_remaining.zero?

        uri = redirect_uri(uri, response['location'])
        redirects_remaining -= 1
      end
    end
  rescue SsrfFilter::Error => e
    raise ArgumentError, e.message
  end

  def self.parse_uri(url)
    uri = URI.parse(url)
    raise ArgumentError, 'URL must be http or https' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    raise ArgumentError, 'URL must have a host' unless uri.hostname
    raise ArgumentError, 'userinfo not supported' if uri.userinfo

    uri
  rescue URI::InvalidURIError, TypeError
    raise ArgumentError, 'URL must be http or https'
  end
  private_class_method :parse_uri

  def self.redirect_uri(uri, location)
    redirected_uri = parse_uri(URI.join(uri.to_s, location).to_s)
    raise ArgumentError, 'HTTPS redirects must remain HTTPS' if uri.scheme == 'https' && redirected_uri.scheme != 'https'

    redirected_uri
  rescue URI::InvalidURIError, TypeError
    raise ArgumentError, 'Invalid redirect URL'
  end
  private_class_method :redirect_uri

  def self.raise_http_error(response)
    raise OpenURI::HTTPError.new("#{response.code} #{response.message}", response)
  end
  private_class_method :raise_http_error
end
