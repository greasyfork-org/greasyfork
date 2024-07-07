class SiteApplicationsDomainNil < ActiveRecord::Migration[7.1]
  def change
    change_column_null :site_applications, :domain, true
  end
end
