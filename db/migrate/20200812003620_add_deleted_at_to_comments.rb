class AddDeletedAtToComments < ActiveRecord::Migration[6.0]
  def change
    add_column :comments, :deleted_at, :datetime
    add_column :comments, :deleted_by_user_id, :integer
  end
end
