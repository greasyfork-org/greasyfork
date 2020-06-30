class PopulateDiscussionCategory < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL
      INSERT INTO discussion_categories (category_key) VALUES ('greasyfork'), ('development'), ('requests'), ('script-discussions')
    SQL
  end
end
