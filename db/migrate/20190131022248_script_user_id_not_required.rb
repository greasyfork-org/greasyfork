class ScriptUserIdNotRequired < ActiveRecord::Migration[5.2]
  def change
    change_column_null :scripts, :user_id, true
  end
end
