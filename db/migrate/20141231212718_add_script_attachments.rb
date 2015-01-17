class AddScriptAttachments < ActiveRecord::Migration
	def change
		create_table :screenshots
		add_attachment :screenshots, :screenshot
		create_table :screenshots_script_versions do |t|
			t.belongs_to :screenshot, :nil => false, :index => true
			t.belongs_to :script_version, :nil => false, :index => true
		end
	end
end
