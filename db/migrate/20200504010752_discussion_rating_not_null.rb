class DiscussionRatingNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column :discussions, :rating, :integer, null: false, default: 1
  end
end
