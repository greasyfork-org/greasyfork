class AddScriptIdToDiscussions < ActiveRecord::Migration
  def change
	execute 'ALTER TABLE GDN_Discussion ADD COLUMN ScriptID int NULL'
  end
end
