class AddExpiryToPreviouslyBannedDomains < ActiveRecord::Migration[8.0]
  def change
    SpammyEmailDomain.where(expires_at: nil, block_type: SpammyEmailDomain::BLOCK_TYPE_REGISTER).update_all(expires_at: Time.zone.now, block_count: 1)
  end
end
