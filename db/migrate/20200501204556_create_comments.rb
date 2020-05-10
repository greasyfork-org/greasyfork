class CreateComments < ActiveRecord::Migration[6.0]
  def change
    create_table :comments do |t|
      t.timestamps
      t.belongs_to :discussion, null: false
      t.integer :poster_id, null: false
      t.text :text, null: false
      t.string :text_markup, limit: 10, default: "html", null: false
    end
    add_foreign_key :comments, :discussions, on_delete: :cascade
  end
end
