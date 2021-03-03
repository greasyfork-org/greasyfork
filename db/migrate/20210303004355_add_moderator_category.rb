class AddModeratorCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :discussion_categories, :moderators_only, :boolean, default: false, null: false
    execute "INSERT INTO discussion_categories (category_key, moderators_only) VALUES ('moderators', true)"
  end
end
