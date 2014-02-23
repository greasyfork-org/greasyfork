class AddUrlToAllowedRequires < ActiveRecord::Migration
	def change
		add_column :allowed_requires, :url, :string, :limit => 500
	end
end
