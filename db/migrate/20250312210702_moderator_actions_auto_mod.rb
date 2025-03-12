class ModeratorActionsAutoMod < ActiveRecord::Migration[8.0]
  def change
    change_column_null :moderator_actions, :moderator_id, true
    add_column :moderator_actions, :automod, :boolean, default: false, null: false
  end
end
