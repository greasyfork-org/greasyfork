class AddIndexToDiscussionsMigratedFrom < ActiveRecord::Migration[6.1]
  def change
    add_index :discussions, :migrated_from
  end
end
