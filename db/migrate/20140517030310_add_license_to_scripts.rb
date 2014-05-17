class AddLicenseToScripts < ActiveRecord::Migration
	def change
		add_column :scripts, :license_text, :string, :limit => 500
		add_column :scripts, :license_id, :integer
	end
end
