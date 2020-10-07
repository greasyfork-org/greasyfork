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

      record.disallowed_requires_used.each { |w| record.errors.add(:code, I18n.t('errors.messages.script_disallowed_require', code: "@require #{w}")) }
    end
  end
end
