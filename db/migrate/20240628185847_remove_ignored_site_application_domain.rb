class RemoveIgnoredSiteApplicationDomain < ActiveRecord::Migration[7.1]
  def change
    remove_column :site_applications, :domain
  end
end
