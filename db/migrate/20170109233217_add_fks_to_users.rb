class AddFksToUsers < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :scripts, :users
    add_foreign_key :scripts, :users, on_delete: :cascade
    add_foreign_key :identities, :users, on_delete: :cascade
    add_foreign_key :script_sets, :users, on_delete: :cascade
    add_foreign_key :roles_users, :users, on_delete: :cascade
  end
end
