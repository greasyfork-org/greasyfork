class InstallCountsBigInt < ActiveRecord::Migration[7.1]
  def change
    execute <<~SQL
      ALTER TABLE install_counts MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT
    SQL
  end
end
