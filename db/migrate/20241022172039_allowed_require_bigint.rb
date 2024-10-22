class AllowedRequireBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :allowed_requires, :id, :bigint, auto_increment: true
  end
end
