class CreateDiscussionCategory < ActiveRecord::Migration[6.0]
  def change
    create_table :discussion_categories do |t|
      t.string :category_key, null: false, limit: 20
    end
  end
end
