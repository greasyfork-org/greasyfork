class AddCaptionToScreenshots < ActiveRecord::Migration
	def change
		add_column :screenshots, :caption, :string, :limit => 500
	end
end
