class DailyInstallCountsIpv6 < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      ALTER TABLE daily_install_counts
      MODIFY COLUMN ip VARCHAR(45) NOT NULL
    SQL
    execute <<~SQL
      ALTER TABLE daily_update_check_counts
      MODIFY COLUMN ip VARCHAR(45) NOT NULL
    SQL
  end
end
