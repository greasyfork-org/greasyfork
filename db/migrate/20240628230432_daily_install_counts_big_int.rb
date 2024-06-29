class DailyInstallCountsBigInt < ActiveRecord::Migration[7.1]
  def change
    execute <<~SQL
      ALTER TABLE daily_install_counts MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT
    SQL
  end
end
