class AddMigratedFromToDiscussions < ActiveRecord::Migration[6.0]
  def change
    add_column :discussions, :migrated_from, :integer
  end
end
