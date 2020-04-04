class ScriptDeleteType < ApplicationRecord
  KEEP = 1
  BLANKED = 2

  def keep?
    id == KEEP
  end
end
