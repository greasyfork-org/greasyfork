class CreateLicenses < ActiveRecord::Migration
	def change
		create_table :licenses do |t|
			t.string :name, :limit => 100, :null => false
			t.string :pattern, :limit => 1000, :null => false
			t.string :html, :limit => 1000, :null => false
			t.integer :priority, :null => false, :index => true
		end
	end
end
