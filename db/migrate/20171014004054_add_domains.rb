class AddDomains < ActiveRecord::Migration[5.1]
  def change
    create_table(:site_applications, options: 'DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci') do |t|
      t.text :text, limit: 1000, null: false, unique: true
      t.boolean :domain, null: false
    end
    add_column :script_applies_tos, :site_application_id, :int, after: :text
    execute 'INSERT INTO site_applications (text, domain) (SELECT DISTINCT text, domain from script_applies_tos)'
    execute 'UPDATE script_applies_tos JOIN site_applications on site_applications.text = script_applies_tos.text SET site_application_id = site_applications.id'
    change_column :script_applies_tos, :site_application_id, :int, null: false, foreign_key: true
    remove_column :script_applies_tos, :text
    remove_column :script_applies_tos, :domain
  end
end
