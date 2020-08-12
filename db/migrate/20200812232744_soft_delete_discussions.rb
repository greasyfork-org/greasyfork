class SoftDeleteDiscussions < ActiveRecord::Migration[6.0]
  def change
    add_column :discussions, :deleted_at, :datetime
    add_column :discussions, :deleted_by_user_id, :integer
  end
end
