class AddIndexToModeratorActionUserId < ActiveRecord::Migration[6.1]
  def change
    add_index :moderator_actions, :user_id
  end
end
