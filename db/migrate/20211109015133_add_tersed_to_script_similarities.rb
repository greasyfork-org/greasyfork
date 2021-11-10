class AddTersedToScriptSimilarities < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :script_similarities, :scripts, column: :script_id
    remove_index :script_similarities, [:script_id, :other_script_id]
    add_column :script_similarities, :tersed, :boolean, null: false, default: false
    add_index :script_similarities, [:script_id, :other_script_id, :tersed], unique: true, name: :script_similarity_search
    add_foreign_key :script_similarities, :scripts, column: :script_id, on_delete: :cascade
  end
end
