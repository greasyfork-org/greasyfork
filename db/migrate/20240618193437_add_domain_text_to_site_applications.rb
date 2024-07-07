class AddDomainTextToSiteApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :site_applications, :domain_text, :string, limit: 100
  end
end
