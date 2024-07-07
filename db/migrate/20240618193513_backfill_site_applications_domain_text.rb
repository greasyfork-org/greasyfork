class BackfillSiteApplicationsDomainText < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      UPDATE site_applications SET domain_text = text WHERE domain_text IS NULL AND domain
    SQL
  end
end
