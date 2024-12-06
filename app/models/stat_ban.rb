class StatBan < ApplicationRecord
  belongs_to :script

  scope :active, -> { where('expires_at > NOW()') }

  def self.add_next_ban!(script_id)
    previous_bans = StatBan.where(script_id:).count
    ban_length_days = 2 ^ (previous_bans + 1)
    Rails.logger.info("Banning script #{script_id} for #{ban_length_days} days")
    StatBan.create!(script_id:, expires_at: ban_length_days.days.from_now)
  end
end
