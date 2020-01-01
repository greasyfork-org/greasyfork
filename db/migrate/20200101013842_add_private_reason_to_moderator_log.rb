class AddPrivateReasonToModeratorLog < ActiveRecord::Migration[6.0]
  def change
    add_column :moderator_actions, :private_reason, :string, limit: 500
  end
end
