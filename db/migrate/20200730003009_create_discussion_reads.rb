class CreateDiscussionReads < ActiveRecord::Migration[6.0]
  def change
    create_table :discussion_reads do |t|
      t.belongs_to :discussion, null: false
      t.belongs_to :user, null: false, type: :integer, index: false
      t.datetime :read_at, null: false
    end
    add_foreign_key :discussion_reads, :discussions, on_delete: :cascade
    add_foreign_key :discussion_reads, :users, on_delete: :cascade
    add_index :discussion_reads, [:user_id, :discussion_id], unique: true
  end
end
