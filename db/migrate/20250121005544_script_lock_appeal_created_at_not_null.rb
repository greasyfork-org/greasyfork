class ScriptLockAppealCreatedAtNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :script_lock_appeals, :created_at, false
  end
end
