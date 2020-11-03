class CreateUserReferences < ActiveRecord::Migration[6.0]
  def change
    create_table :mentions do |t|
      t.belongs_to :mentioning_item, null: false, index: false, polymorphic: true
      t.integer :user_id, null: false
      t.string :text, null: false
    end
    add_index :mentions, [:mentioning_item_type, :mentioning_item_id, :user_id], name: 'mention_mentioning'
    add_foreign_key :mentions, :users
  end
end
