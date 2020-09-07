class UserBannedAt < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :banned_at, :datetime
  end
end
