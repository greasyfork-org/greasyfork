class CreateLocaleContributors < ActiveRecord::Migration
	def change
		create_table :locale_contributors do |t|
			t.belongs_to :locale, :null => false, :index => true
			t.string :transifex_user_name, :limit => 50, :null => false
		end
	end
end
