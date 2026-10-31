class CreateTokenShingleSimilarities < ActiveRecord::Migration[8.1]
  def change
    create_table :token_shingle_similarities do |t|
      t.bigint :script_id, null: false
      t.bigint :other_script_id, null: false
      t.decimal :similarity, precision: 4, scale: 3, null: false
      t.datetime :checked_at, null: false
      t.timestamps

      t.index [:script_id, :other_script_id], unique: true, name: 'token_shingle_similarity_pair'
      t.index [:other_script_id, :script_id], name: 'index_token_shingle_similarities_on_other_script'
    end

    add_foreign_key :token_shingle_similarities, :scripts, on_delete: :cascade
    add_foreign_key :token_shingle_similarities, :scripts, column: :other_script_id, on_delete: :cascade
  end
end
