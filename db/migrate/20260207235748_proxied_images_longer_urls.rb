class ProxiedImagesLongerUrls < ActiveRecord::Migration[8.1]
  def change
    change_column :proxied_images, :original_url, :string, null: false, limit: 1000
  end
end
