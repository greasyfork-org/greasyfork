class AddReportNotSensitive < ActiveRecord::Migration
	def change
		add_column :scripts, :not_adult_content_self_report_date, :datetime
	end
end
