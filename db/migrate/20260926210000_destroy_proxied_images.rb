class DestroyProxiedImages < ActiveRecord::Migration[8.1]
  def up
    ProxiedImage.find_each(&:destroy!)
  end
end
