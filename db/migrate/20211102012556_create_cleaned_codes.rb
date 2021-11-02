class CreateCleanedCodes < ActiveRecord::Migration[6.1]
  def change
    create_table :cleaned_codes do |t|
      t.integer :script_id, null: false
      t.text :code, null: false
    end
    add_foreign_key :cleaned_codes, :scripts, on_delete: :cascade
  end
end
