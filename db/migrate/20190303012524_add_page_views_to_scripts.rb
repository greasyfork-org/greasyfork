class AddPageViewsToScripts < ActiveRecord::Migration[5.2]
  def change
    add_column :scripts, :page_views, :integer, null: false, default: 0
  end
end
