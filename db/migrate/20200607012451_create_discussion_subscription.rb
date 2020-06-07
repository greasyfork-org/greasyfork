class CreateDiscussionSubscription < ActiveRecord::Migration[6.0]
  def change
    create_table :discussion_subscriptions do |t|
      t.belongs_to :discussion, null: false, index: false
      t.belongs_to :user, null: false, type: :integer
      t.timestamps
    end
    add_foreign_key :discussion_subscriptions, :discussions, on_delete: :cascade
    add_foreign_key :discussion_subscriptions, :users, on_delete: :cascade
    add_index :discussion_subscriptions, [:discussion_id, :user_id], unique: true
  end
end
