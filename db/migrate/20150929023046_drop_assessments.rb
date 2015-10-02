class DropAssessments < ActiveRecord::Migration
	def up
		drop_table :assessments
		drop_table :assessment_reasons
		execute 'update scripts set script_delete_type_id = 1, locked = true where uses_disallowed_external;'
		remove_column :scripts, :uses_disallowed_external
	end
end
