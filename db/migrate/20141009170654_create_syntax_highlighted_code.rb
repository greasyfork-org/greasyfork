class CreateSyntaxHighlightedCode < ActiveRecord::Migration
	def change
		create_table :syntax_highlighted_codes do |t|
			t.references :script, :null => false, :index => true, :unique => true
			t.text :html, :limit => 10000000, :null => false
		end
	end
end
