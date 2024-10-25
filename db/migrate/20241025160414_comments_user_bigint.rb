class CommentsUserBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :comments, :poster_id, :bigint
    change_column :comments, :deleted_by_user_id, :bigint
  end
end
