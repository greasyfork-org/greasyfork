class ScriptUserscriptsId < ActiveRecord::Migration
  def change
    add_column :scripts, :userscripts_id, :integer
  end
end
