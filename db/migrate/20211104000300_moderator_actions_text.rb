class ModeratorActionsText < ActiveRecord::Migration[6.1]
  def change
    change_column :moderator_actions, :action, :text
    change_column :moderator_actions, :private_reason, :text
  end
end
