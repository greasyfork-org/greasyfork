class CreateBlockedUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :blocked_users do |t|
      t.timestamps
      t.string :pattern, null: false
    end
  end
end
