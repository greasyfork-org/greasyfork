class AdjustSiteApplicationIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :site_applications, name: :index_site_applications_on_text_and_domain
    add_index :site_applications, :domain_text, unique: true
  end
end
