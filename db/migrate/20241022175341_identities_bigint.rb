class IdentitiesBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :identities, :id, :bigint, auto_increment: true
  end
end
