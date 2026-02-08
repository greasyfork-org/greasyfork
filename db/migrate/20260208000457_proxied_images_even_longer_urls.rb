class ProxiedImagesEvenLongerUrls < ActiveRecord::Migration[8.1]
  def change
    change_column :proxied_images, :original_url, :string, null: false, limit: 2000
  end
end
