class RatingNil < ActiveRecord::Migration[6.0]
  def change
    change_column :discussions, :rating, :integer, null: true, default: nil
  end
end
