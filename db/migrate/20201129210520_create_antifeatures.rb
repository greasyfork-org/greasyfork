class CreateAntifeatures < ActiveRecord::Migration[6.0]
  def change
    create_table :antifeatures do |t|
      t.belongs_to :script, null: false, type: :integer
      t.belongs_to :locale, type: :integer
      t.integer :antifeature_type, null: false
      t.text :description
    end
    add_foreign_key :antifeatures, :scripts, on_delete: :cascade
    add_foreign_key :antifeatures, :locales, on_delete: :restrict
  end
end
