class DropScriptSimilarities < ActiveRecord::Migration[8.1]
  def change
    drop_table :script_similarities, if_exists: true
  end
end
