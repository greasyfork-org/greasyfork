class ProxiedImage < ApplicationRecord
  has_one_attached :image

  SAFE_HOSTS = ['greasyfork.org', 'sleazyfork.org', 'amazonaws.com', 'github.com', 'shields.io', 'gitlab.com', 'githubusercontent.com'].freeze

  def self.uri_needs_to_be_proxied?(uri)
    SAFE_HOSTS.none?{|safe_host| uri.host == safe_host || uri.host&.end_with?(".#{safe_host}") }
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
    downloaded_image = uri.open(read_timeout: 10)
    content_type = downloaded_image.content_type

    raise "Unsupported content type: #{content_type}" unless HasAttachments::ALLOWED_CONTENT_TYPES.include?(content_type)

    image.attach(
      io: downloaded_image,
      filename: File.basename(uri.path),
      content_type: content_type
    )

    self.success = true
    self.last_error = nil
  rescue StandardError => e
    self.success = false
    self.last_error = e.message.truncate(500)
  ensure
    save!
  end

  def self.validate_url!(url)
    uri = URI.parse(url)
    raise "Invalid URI" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    uri
  end
end