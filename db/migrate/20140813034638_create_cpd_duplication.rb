class CreateCpdDuplication < ActiveRecord::Migration
	def change
		create_table :cpd_duplications do |t|
			t.integer :lines, :null => false
			t.timestamps
		end
		create_table :cpd_duplication_scripts do |t|
			t.references :cpd_duplication, :null => false, :index => true
			t.references :script, :null => false, :index => true
			t.integer :line, :null => false
		end
	end
end
