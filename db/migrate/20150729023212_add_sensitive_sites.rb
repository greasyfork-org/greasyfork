class AddSensitiveSites < ActiveRecord::Migration
	def change
		add_column :scripts, :sensitive, :boolean, null: false, default: false
		create_table :sensitive_sites do |t|
			t.string :domain, limit: 150, null: false
		end
		add_index :sensitive_sites, :domain, unique: true
	end
end
