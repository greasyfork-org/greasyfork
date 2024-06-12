class BlockedScriptCode < ApplicationRecord
  belongs_to :originating_script, class_name: 'Script', optional: true

  def match?(code)
    Regexp.new(pattern, case_insensitive ? Regexp::IGNORECASE : nil).match?(code)
  end
end
