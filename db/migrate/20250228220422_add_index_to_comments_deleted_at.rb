class AddIndexToCommentsDeletedAt < ActiveRecord::Migration[8.0]
  def change
    add_index :comments, :deleted_at
  end
end
