class AddPercentCompleteToLocale < ActiveRecord::Migration
	def change
		add_column :locales, :percent_complete, :int, :nil => false, :default => 0
		execute 'update locales set percent_complete = 100 where code = "en"'
	end
end
