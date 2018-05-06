class CreateDisallowedAttributes < ActiveRecord::Migration[5.1]
  def change
    create_table :disallowed_attributes do |t|
      t.string :attribute_name, null: false, limit: 50
      t.string :pattern, null: false
      t.string :reason, null: false
    end
  end
end
