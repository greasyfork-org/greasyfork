class AddCreatedAtToScriptLockAppeals < ActiveRecord::Migration[8.0]
  def change
    add_column :script_lock_appeals, :created_at, :datetime
  end
end
