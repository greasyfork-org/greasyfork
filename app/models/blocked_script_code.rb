class BlockedScriptCode < ApplicationRecord
  belongs_to :originating_script, class_name: 'Script', optional: true

  def match?(code)
    Regexp.new(pattern).match?(code)
  end
end
