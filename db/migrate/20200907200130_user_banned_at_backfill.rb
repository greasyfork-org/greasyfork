class UserBannedAtBackfill < ActiveRecord::Migration[6.0]
  def up
    execute 'update users set banned_at = coalesce(updated_at, CURRENT_TIMESTAMP) where banned = 1'
  end
end
