class RefactorScriptAppliesTos < ActiveRecord::Migration
	def change
		change_table(:script_applies_tos) do |t|
			t.remove :pattern
			t.remove :display_text
			t.remove :created_at
			t.remove :updated_at
			t.text :text, :limit => 500, :null => false, :index => true
			t.boolean :domain, :null => false, :index => true
		end
	end
end
