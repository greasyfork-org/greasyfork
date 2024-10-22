class ScriptVersionsBigint < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :localized_script_version_attributes, :script_versions
    change_column :localized_script_version_attributes, :script_version_id, :bigint

    change_column :script_versions, :id, :bigint, auto_increment: true

    add_foreign_key :localized_script_version_attributes, :script_versions, on_delete: :cascade
  end
end
