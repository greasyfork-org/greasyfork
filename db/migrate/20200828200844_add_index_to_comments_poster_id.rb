class AddIndexToCommentsPosterId < ActiveRecord::Migration[6.0]
  def change
    add_index :comments, :poster_id
  end
end
