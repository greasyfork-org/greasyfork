class AddConsecutiveBadRatingsAtToScripts < ActiveRecord::Migration[6.0]
  def change
    add_column :scripts, :consecutive_bad_ratings_at, :datetime
  end
end
