class ModeratorActionActionTakenNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :moderator_actions, :action_taken, false
    change_column_null :moderator_actions, :action, true
  end
end
