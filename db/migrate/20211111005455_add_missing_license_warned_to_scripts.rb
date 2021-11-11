class AddMissingLicenseWarnedToScripts < ActiveRecord::Migration[6.1]
  def change
    add_column :scripts, :missing_license_warned, :boolean, null: false, default: false
  end
end
