class RolesBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :roles, :id, :bigint, auto_increment: true
  end
end
