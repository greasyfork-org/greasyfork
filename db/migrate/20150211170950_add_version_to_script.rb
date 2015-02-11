class AddVersionToScript < ActiveRecord::Migration
	def change
		change_column :script_versions, :version, :string, :limit => 200, :null => false
		add_column :scripts, :version, :string, :limit => 200, :null => false
		execute <<-EOF
			update scripts join script_versions on script_id = scripts.id set scripts.version = script_versions.version where script_versions.id in (select max(id) from script_versions group by script_id)
		EOF
	end
end
