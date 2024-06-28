class AddPubliclyVisibleToDiscussions < ActiveRecord::Migration[7.1]
  def change
    add_column :discussions, :publicly_visible, :boolean, null: false, default: true
  end
end
