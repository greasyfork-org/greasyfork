class AddActionTakenToModeratorAction < ActiveRecord::Migration[8.0]
  def change
    add_column :moderator_actions, :action_taken, :integer
    add_column :moderator_actions, :action_details, :text
  end
end
