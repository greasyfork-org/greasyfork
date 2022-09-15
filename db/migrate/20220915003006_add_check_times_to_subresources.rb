class AddCheckTimesToSubresources < ActiveRecord::Migration[7.0]
  def change
    add_column :subresources, :last_attempt_at, :datetime
    add_column :subresources, :last_success_at, :datetime
    add_column :subresources, :last_change_at, :datetime
  end
end
