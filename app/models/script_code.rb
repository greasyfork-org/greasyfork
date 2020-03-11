require 'digest'

class ScriptCode < ApplicationRecord
  before_save do
    self.code_hash = calculate_hash
  end

  def calculate_hash
    self.code_hash = Digest::SHA1.hexdigest code
  end
end
