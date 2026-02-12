class AddHostToProxiedImages < ActiveRecord::Migration[8.1]
  def change
    add_column :proxied_images, :original_host, :string, limit: 200, null: true

    ProxiedImage.find_each do |proxied_image|
      proxied_image.update!(original_host: URI.parse(proxied_image.original_url).host)
    end
    
    change_column_null :proxied_images, :original_host, false
  end
end
