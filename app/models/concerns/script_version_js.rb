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
          # Seems like this can mangle encoding, so fix it so we show something instead of an encoding error in the view.
          # https://github.com/rubyjs/mini_racer/issues/369
          record.errors.add(:code, "contains errors: #{message.encode('UTF-8', invalid: :replace, undef: :replace, replace: '�')}")
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
end
