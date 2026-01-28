class ProxiedImage < ApplicationRecord
  has_one_attached :image

  SAFE_HOSTS = ['greasyfork.org', 'sleazyfork.org'].freeze

  def self.proxied_url_for_url(original_url)
    # Ensure it's something we would actually want to use.
    begin
      uri = validate_url!(original_url)
    rescue StandardError
      return nil
    end

    return original_url if SAFE_HOSTS.include?(uri.host)

    proxied_image = find_by(original_url:)

    # If we have not attempted to proxy this image yet, enqueue a job and use the original URL for now.
    if proxied_image.nil?
      ProxiedImageFetchJob.perform_async(original_url)
      return original_url
    end

    # If we have a successful proxy, return the proxied URL.
    return url_for(image.blob) if proxied_image.success

    # If we attempted but failed to proxy, return nil and render nothing. We could return the original, but this would
    # by a bypass of the original intent of preventing tracking via third-party image hosts.
    nil
  end

  def self.store(original_url, refresh_if_exists: false)
    proxied_image = if refresh_if_exists
                      find_or_initialize_by(original_url:)
                    else
                      find_by(original_url:)
                    end

    return unless proxied_image

    begin
      uri = validate_url!(original_url)
      downloaded_image = uri.read({ read_timeout: 10 })
      content_type = downloaded_image.content_type

      raise "Unsupported content type: #{content_type}" unless HasAttachments::ALLOWED_CONTENT_TYPES.include?(content_type)

      proxied_image.image.attach(
        io: downloaded_image,
        filename: File.basename(uri.path),
        content_type: content_type
      )

      proxied_image.success = true
      proxied_image.last_error = nil
    rescue StandardError => e
      proxied_image.success = false
      proxied_image.last_error = e.message.truncate(500)
    ensure
      proxied_image.save!
    end
  end

  def self.validate_url!(url)
    uri = URI.parse(url)
    raise "Invalid URI" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    uri
  end
end