class CreateStatBans < ActiveRecord::Migration[7.2]
  def change
    create_table :stat_bans do |t|
      t.belongs_to :script, null: false, foreign_key: true
      t.timestamps
      t.datetime :expires_at, null: false
    end
  end
end
