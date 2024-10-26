class ScriptLockAppealIdBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :moderator_actions, :script_lock_appeal_id, :bigint
  end
end
