class AddReviewReasonToComments < ActiveRecord::Migration[7.0]
  def change
    add_column :comments, :review_reason, :string, limit: 10
  end
end
