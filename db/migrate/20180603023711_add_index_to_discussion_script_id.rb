class AddIndexToDiscussionScriptId < ActiveRecord::Migration[5.2]
  def change
    add_index :GDN_Discussion, :ScriptID
  end
end
