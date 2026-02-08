class ProxiedImage < ApplicationRecord
  has_one_attached :image

  scope :expired, -> { where(expires_at: ...Time.current) }

  SAFE_HOSTS = ['greasyfork.org', 'sleazyfork.org', 'amazonaws.com', 'github.com', 'shields.io', 'gitlab.com', 'githubusercontent.com'].freeze

  def self.uri_needs_to_be_proxied?(uri)
    SAFE_HOSTS.none? { |safe_host| uri.host == safe_host || uri.host&.end_with?(".#{safe_host}") }
  end

  def self.proxied_url_for_url(original_url)
    # Ensure it's something we would actually want to use.
    begin
      uri = validate_url!(original_url)
    rescue StandardError
      return nil
    end

    return original_url unless uri_needs_to_be_proxied?(uri)

    proxied_image = find_by(original_url:)

    # If we have not attempted to proxy this image yet, enqueue a job and use the original URL for now.
    if proxied_image.nil?
      ProxiedImageFetchJob.perform_async(original_url)
      return original_url
    end

    # If we have a successful proxy, return the proxied URL.
    return proxied_image.image.blob.url if proxied_image.success

    # If we attempted but failed to proxy, return nil and render nothing. We could return the original, but this would
    # by a bypass of the original intent of preventing tracking via third-party image hosts.
    nil
  end

  def self.store(original_url, refresh_if_exists: false)
    proxied_image = find_by(original_url:)
    return if proxied_image && !refresh_if_exists

    proxied_image ||= ProxiedImage.new(original_url:)
    proxied_image.load_media
  end

  def load_media
    uri = self.class.validate_url!(original_url)

    uri.open(read_timeout: 10, open_timeout: 10) do |f|
      content_type = f.content_type
      raise "Unsupported content type: #{content_type}" unless HasAttachments::ALLOWED_CONTENT_TYPES.include?(content_type)

      if f.meta.key?('expires')
        self.expires_at = Time.zone.parse(f.meta['expires'])
      elsif (max_age = f.meta['cache-control']&.match(/max-age=(\d+)/)&.[](1)&.to_i)
        self.expires_at = max_age.seconds.from_now
      end

      # Minimum 1 day TTL
      self.expires_at = 1.day.from_now if expires_at.nil? || expires_at < 1.day.from_now

      self.size = f.size

      image.attach(
        io: f,
        filename: File.basename(uri.path),
        content_type: content_type
      )

      self.success = true
      self.last_error = nil

      save!
    end
  rescue StandardError => e
    self.success = false
    self.expires_at = 1.day.from_now
    self.size = 0
    self.last_error = e.message.truncate(500)
    save!
  end

  def self.validate_url!(url)
    raise 'URL is too long' if url.length > 2000

    uri = URI.parse(url)
    raise 'Invalid URI' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    uri
  end
end
