class CreateSubresources < ActiveRecord::Migration[7.0]
  def change
    create_table :subresources do |t|
      t.string :url, null: false
      t.timestamps
    end
    add_index :subresources, :url, unique: true
    create_table :script_subresource_usages do |t|
      t.references :script, null: false
      t.references :subresource, null: false
      t.string :algorithm, limit: 20
      t.string :integrity_hash, limit: 128
    end
  end
end
