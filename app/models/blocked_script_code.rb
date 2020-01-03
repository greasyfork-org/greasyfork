class BlockedScriptCode < ApplicationRecord
  def match?(code)
    Regexp.new(pattern).match?(code)
  end
end