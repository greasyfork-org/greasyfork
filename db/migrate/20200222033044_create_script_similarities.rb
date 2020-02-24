class CreateScriptSimilarities < ActiveRecord::Migration[6.0]
  def change
    create_table :script_similarities do |t|
      t.integer :script_id, null: false
      t.integer :other_script_id, null: false
      t.decimal :similarity, precision: 4, scale: 3, null: false
      t.datetime :checked_at, null: false
    end
    add_index :script_similarities, [:script_id, :other_script_id], unique: true
    add_foreign_key :script_similarities, :scripts, on_delete: :cascade
    add_foreign_key :script_similarities, :scripts, column: :other_script_id, on_delete: :cascade
  end
end
