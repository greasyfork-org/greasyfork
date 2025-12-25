class UrlToScriptService
  def self.to_script(value, allow_deleted: false, verify_existence: true)
    allowed_hosts = ['https://greasyfork.org', 'https://sleazyfork.org', 'https://cn-greasyfork.org']
    allowed_hosts += ['https://greasyfork.local', 'https://sleazyfork.local', 'https://cn-greasyfork.local'] unless Rails.env.production?

    return nil if value.blank?

    script_id = nil
    # Is it an ID?
    if value.to_i != 0
      script_id = value.to_i
    # A non-GF URL?
    elsif allowed_hosts.none? { |host| value.start_with?(host) && !value.start_with?('/') }
      return :non_gf_url
    # A GF URL?
    else
      url_match = %r{/scripts/([0-9]+)(-|$)}.match(value)
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
end
