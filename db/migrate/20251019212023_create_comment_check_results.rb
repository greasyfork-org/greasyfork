class CreateCommentCheckResults < ActiveRecord::Migration[8.0]
  def change
    create_table :comment_check_results do |t|
      t.bigint :comment_id, null: false
      t.string :strategy, limit: 50, null: false
      t.integer :result, null: false
    end
    add_foreign_key :comment_check_results, :comments, on_delete: :cascade
  end
end
