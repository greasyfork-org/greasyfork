class SensitiveSitesBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :sensitive_sites, :id, :bigint, auto_increment: true
  end
end
