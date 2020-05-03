class CreateReports < ActiveRecord::Migration[6.0]
  def change
    create_table :reports do |t|
      t.references :item, polymorphic: true, null: false, index: true
      t.string :reason, limit: 20, null: false
      t.text :explanation
      t.integer :reporter_id, null: false, index: true
      t.string :result, limit: 20, index: true
    end
    add_foreign_key :reports, :users, column: :reporter_id, on_delete: :cascade
  end
end
