class AddAppealToModeratorLog < ActiveRecord::Migration[6.1]
  def change
    add_column :moderator_actions, :script_lock_appeal_id, :integer
  end
end
