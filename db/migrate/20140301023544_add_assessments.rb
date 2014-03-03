class AddAssessments < ActiveRecord::Migration
	def change
		create_table :assessment_reasons do |t|
			t.string :name, :null => false, :length => 20
			t.timestamps
		end
		create_table :assessments do |t|
			t.references :script, :null => false
			t.references :assessment_reason, :null => false
			t.string :details, :null => true, :length => 500
			t.timestamps
		end
		reversible do |dir|
			dir.up do
				execute <<-EOF
					insert into assessment_reasons (name) values ('@require')
				EOF
			end
		end
	end
end
