require 'active_support/concern'

module ScriptVersionJs
  extend ActiveSupport::Concern

  included do
    validates_each :code, on: :create do |record, _attr, value|
      next unless record.new_record? && record.js?

      js = JsChecker.new(value, allow_json: record.script.library?)
      if js.check
        record.script.has_syntax_error = false
      else
        js.errors.each do |_type, message|
          record.script.has_syntax_error = true
          record.errors.add(:code, "contains errors: #{message}")
        end
      end
    end

    validate on: :create do |record|
      next unless record.js?

      record.disallowed_requires_used.each do |url, type|
        if type == :disallowed
          if url.starts_with?('data:') && url.include?('base64')
            record.errors.add(:code, I18n.t('errors.messages.script_disallowed_base_64_require'))
          else
            record.errors.add(:code, I18n.t('errors.messages.script_disallowed_require', code: "@require #{url.truncate(1000)}"))
          end
        else
          record.errors.add(:code, I18n.t('errors.messages.script_malformed_require', code: "@require #{url.truncate(1000)}"))
        end
      end
    end

    validate on: :create do |record|
      next unless record.js?

      resources = meta['resource'] || []
      allowed_resource_regex = URI::DEFAULT_PARSER.make_regexp(%w[http https data])
      resources.map { |resource| [resource, resource.split(/\s+/, 2).last] }.reject { |_full_value, url| allowed_resource_regex.match?(url) || url.starts_with?('//') }.each do |full_value, _url|
        record.errors.add(:code, I18n.t('errors.messages.script_disallowed_resource', code: "@resource #{full_value}"))
      end
    end
  end

  def disallowed_requires_used
    r = []

    # Get all the requires
    meta = parser_class.parse_meta(code)
    return r unless meta.key?('require')

    # Filter out the allowlisted ones
    non_allowlisted_requires = []
    allowed_requires = AllowedRequire.all
    meta['require'].each do |script_url|
      if script_url.starts_with?('data:')
        non_allowlisted_requires << script_url if script_url.include?(';base64,')
        next
      end

      uri = URI(script_url).normalize.to_s

      next if /\A[^#]+#(md5|sha1|sha256|sha384|sha512)[=-]/.match?(script_url)

      non_allowlisted_requires << script_url if allowed_requires.none? { |ar| uri =~ Regexp.new(ar.pattern) }
    rescue URI::InvalidURIError
      r << [script_url, :malformed]
    end

    # Allow any that match all @includes and @matches
    applies_to_names = calculate_applies_to_names
    eligible_for_matching = applies_to_names.any? && applies_to_names.all? { |atn| atn[:domain] }
    if eligible_for_matching
      domains = applies_to_names.pluck(:text)
      non_domain_matched_requires = non_allowlisted_requires.reject do |require|
        require_host = URI(require).host
        next false unless require_host

        domains.all? { |domain| require_host == domain || require_host.ends_with?(".#{domain}") }
      end
    else
      non_domain_matched_requires = non_allowlisted_requires
    end
    r.concat(non_domain_matched_requires.map { |require| [require, :disallowed] })

    r
  end
end
