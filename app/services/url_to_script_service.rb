class UrlToScriptService
  def self.to_script(value, allow_deleted: false, verify_existence: true)
    return nil if value.blank?

    script_id = nil
    # Is it an ID?
    if value.to_i != 0
      script_id = value.to_i
    # A non-GF URL?
    elsif !gf_url?(value)
      return :non_gf_url
    # A GF URL?
    else
      url_match = %r{/scripts/([0-9]+)(-|$|/)}.match(value)
      return :non_script_url if url_match.nil?

      script_id = url_match[1].to_i
    end

    return script_id unless verify_existence

    # Validate it's a good replacement
    begin
      script = Script.find(script_id)
    rescue ActiveRecord::RecordNotFound
      return :not_found
    end

    return :deleted if !allow_deleted && script.deleted?

    return script
  end

  ALLOWED_HOSTS = ['greasyfork.org', 'sleazyfork.org', 'cn-greasyfork.org'].freeze
  ADDITIONAL_DEV_HOSTS = ['greasyfork.local', 'sleazyfork.local', 'cn-greasyfork.local'].freeze

  def self.gf_url?(url)
    url = URI.parse(url)
    return false unless url.is_a?(URI::HTTP) && url.host

    hosts_to_check = ALLOWED_HOSTS
    hosts_to_check += ADDITIONAL_DEV_HOSTS unless Rails.env.production?

    hosts_to_check.any? { |host| url.host == host || url.host.ends_with?(".#{host}") }
  rescue URI::InvalidURIError
    false
  end
end
