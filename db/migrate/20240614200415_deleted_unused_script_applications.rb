class DeletedUnusedScriptApplications < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    SiteApplication.connection.select_values('SELECT id from site_applications WHERE id NOT IN (select site_application_id FROM script_applies_tos)').each do |site_application_id|
      SiteApplication.where(id: site_application_id).delete_all
    end
  end
end
