class AddReviewReasonToDiscussions < ActiveRecord::Migration[6.0]
  def change
    add_column :discussions, :review_reason, :string, limit: 10
  end
end
