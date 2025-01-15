class BlockedScriptCode < ApplicationRecord
  belongs_to :originating_script, class_name: 'Script', optional: true

  enum :category, { repost: 0, obfuscation: 1, legal: 2, spam: 3 }

  def match?(code)
    Regexp.new(pattern, case_insensitive ? Regexp::IGNORECASE : nil).match?(code)
  end

  def exempt_script?(script)
    return false unless script

    return true if repost? && script.created_at && script.created_at <= 1.month.ago

    originating_script_id && (originating_script.authors.map(&:user_id) & script.authors.map(&:user_id)).any?
  end
end
