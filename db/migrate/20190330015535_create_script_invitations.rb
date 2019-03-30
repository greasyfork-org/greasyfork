class CreateScriptInvitations < ActiveRecord::Migration[5.2]
  def change
    create_table :script_invitations do |t|
      t.integer :script_id, null: false
      t.integer :invited_user_id, null: false
      t.datetime :expires_at, null: false
    end
    add_foreign_key :script_invitations, :scripts, on_delete: :cascade
    add_foreign_key :script_invitations, :users, column: :invited_user_id, on_delete: :cascade
  end
end
