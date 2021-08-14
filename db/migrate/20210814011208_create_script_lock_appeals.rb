class CreateScriptLockAppeals < ActiveRecord::Migration[6.1]
  def change
    create_table :script_lock_appeals do |t|
      t.integer :script_id, null: false
      t.bigint :report_id
      t.text :text, null: false
      t.string :text_markup, limit: 10, default: "html", null: false
      t.integer :resolution, default: 0, null: false
    end
    add_foreign_key :script_lock_appeals, :scripts, on_delete: :cascade
    add_foreign_key :script_lock_appeals, :reports, on_delete: :cascade
  end
end
