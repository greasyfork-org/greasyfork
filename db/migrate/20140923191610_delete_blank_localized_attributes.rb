class DeleteBlankLocalizedAttributes < ActiveRecord::Migration
	def change
		execute <<-EOF
			delete from localized_script_version_attributes where attribute_value = ''
		EOF
	end
end
