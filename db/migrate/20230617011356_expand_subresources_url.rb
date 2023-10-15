class ExpandSubresourcesUrl < ActiveRecord::Migration[7.0]
  def change
    change_column :subresources, :url, :string, limit: 1024, null: false
  end
end
