class LibraryUsage < ActiveRecord::Migration[8.1]
  def change
    create_table :library_usages do |t|
      t.bigint :script_id, null: false
      t.bigint :library_script_id, null: false
    end

    add_foreign_key :library_usages, :scripts, column: :script_id, on_delete: :cascade
    add_foreign_key :library_usages, :scripts, column: :library_script_id, on_delete: :cascade
  end
end
