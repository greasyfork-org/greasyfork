class LocalizedAttributesBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :localized_script_attributes, :id, :bigint, auto_increment: true
    change_column :localized_script_version_attributes, :id, :bigint, auto_increment: true
  end
end
