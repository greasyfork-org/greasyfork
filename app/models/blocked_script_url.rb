class BlockedScriptUrl < ApplicationRecord
  def readonly?
    true
  end
end