class CreateDiscussions < ActiveRecord::Migration[6.0]
  def change
    create_table :discussions do |t|
      t.timestamps
      t.integer :poster_id, null: false, index: true
      t.integer :script_id
      t.integer :rating
    end
    add_foreign_key :discussions, :scripts, on_delete: :cascade
  end
end
