class DropDuplicateSiteApplications < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    SiteApplication.connection.select_rows('select text, domain, min(id) from site_applications group by text, domain having count(*) > 1;').each do |text, domain, first_id|
      ScriptAppliesTo.joins(:site_application).where(site_application: { text:, domain:}).where.not(site_application_id: first_id).update_all(site_application_id: first_id)
      SiteApplication.where(text:, domain:).where.not(id: first_id).delete_all
    end
  end
end
