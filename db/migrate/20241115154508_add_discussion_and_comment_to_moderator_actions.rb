class AddDiscussionAndCommentToModeratorActions < ActiveRecord::Migration[7.2]
  def change
    change_table :moderator_actions do |t|
      t.bigint :discussion_id, index: true
      t.bigint :comment_id, index: true
    end
  end
end
