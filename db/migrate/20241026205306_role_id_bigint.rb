class RoleIdBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :roles_users, :role_id, :bigint
    add_foreign_key :roles_users, :roles
  end
end
