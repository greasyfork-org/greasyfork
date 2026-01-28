class CreateProxiedImages < ActiveRecord::Migration[8.1]
  def change
    create_table :proxied_images do |t|
      t.timestamps
      t.string :original_url, null: false, index: { unique: true }
      t.boolean :success, null: false, default: false
      t.string :last_error, limit: 500
    end
  end
end
