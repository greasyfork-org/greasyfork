class DropProxiedImages < ActiveRecord::Migration[8.1]
  def change
    drop_table :proxied_images, if_exists: true, charset: 'utf8mb4', collation: 'utf8mb4_unicode_ci' do |t|
      t.timestamps
      t.string :original_url, limit: 2000, null: false
      t.boolean :success, null: false, default: false
      t.string :last_error, limit: 500
      t.datetime :expires_at, null: false
      t.integer :size, null: false
      t.string :original_host, limit: 200, null: false
      t.index :original_url, unique: true, using: :hash
    end
  end
end
