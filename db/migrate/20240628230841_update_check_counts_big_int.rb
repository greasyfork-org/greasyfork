class UpdateCheckCountsBigInt < ActiveRecord::Migration[7.1]
  def change
    execute <<~SQL
      ALTER TABLE update_check_counts MODIFY COLUMN `id` BIGINT NOT NULL AUTO_INCREMENT
    SQL
  end
end
