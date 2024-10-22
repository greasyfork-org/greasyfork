class CompatiblitiesBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :compatibilities, :id, :bigint, auto_increment: true
  end
end
