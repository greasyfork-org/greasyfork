class AddPermanentDeletionRequestDate < ActiveRecord::Migration
	def change
		add_column :scripts, :permanent_deletion_request_date, :datetime
	end
end
