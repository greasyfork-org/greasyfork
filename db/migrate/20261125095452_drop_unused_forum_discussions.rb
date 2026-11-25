class DropUnusedForumDiscussions < ActiveRecord::Migration[8.1]
  def up
    drop_table :GDN_Discussion, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
