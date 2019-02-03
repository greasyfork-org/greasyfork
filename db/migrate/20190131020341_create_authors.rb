class CreateAuthors < ActiveRecord::Migration[5.2]
  def change
    create_table :authors do |t|
      t.integer :script_id, null: false
      t.integer :user_id, null: false
    end
    add_foreign_key :authors, :scripts, on_delete: :cascade
    add_foreign_key :authors, :users, on_delete: :cascade
    add_index :authors, [:script_id, :user_id], unique: true
    execute 'insert into authors (script_id, user_id) (select id, user_id from scripts)'
  end
end
