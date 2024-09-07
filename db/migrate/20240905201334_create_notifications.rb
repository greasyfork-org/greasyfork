class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :item, null: false, polymorphic: true, index: true
      t.integer :notification_type, null: false
      t.datetime :created_at, null: false
      t.datetime :read_at
      t.index [:user_id, :read_at]
      t.index [:user_id, :item_type, :item_id]
      t.index [:user_id, :created_at]
    end
  end
end
