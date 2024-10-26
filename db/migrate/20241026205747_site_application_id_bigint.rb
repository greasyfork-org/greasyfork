class SiteApplicationIdBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :script_applies_tos, :site_application_id, :bigint
    add_foreign_key :script_applies_tos, :site_applications, on_delete: :cascade
  end
end
