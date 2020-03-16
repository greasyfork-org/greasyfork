class DropScriptUserscriptId < ActiveRecord::Migration[6.0]
  def change
    remove_column :scripts, :userscripts_id
  end
end
