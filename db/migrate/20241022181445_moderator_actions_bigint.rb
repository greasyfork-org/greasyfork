class ModeratorActionsBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :moderator_actions, :id, :bigint, auto_increment: true
  end
end
