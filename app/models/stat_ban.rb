class StatBan < ApplicationRecord
  belongs_to :script

  scope :active, -> { where('expires_at > NOW()') }
end
