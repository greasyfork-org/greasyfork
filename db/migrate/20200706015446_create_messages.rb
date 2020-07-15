class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.timestamps
      t.bigint :conversation_id, null: false
      t.integer :poster_id, null: false, index: true
      t.string :content, null: false, limit: 10000
      t.string :content_markup, null: false, default: 'html', limit: 10
    end
    add_foreign_key :messages, :conversations, on_delete: :cascade
  end
end
