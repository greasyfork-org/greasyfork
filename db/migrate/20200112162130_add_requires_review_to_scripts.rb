class AddRequiresReviewToScripts < ActiveRecord::Migration[6.0]
  def change
    add_column :scripts, :review_state, :string, null: false, default: 'not_required'
    add_index :scripts, :review_state
  end
end
