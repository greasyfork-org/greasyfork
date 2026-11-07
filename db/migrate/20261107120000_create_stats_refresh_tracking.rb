class CreateStatsRefreshTracking < ActiveRecord::Migration[8.1]
  def change
    create_table :script_stats_refresh_progresses, charset: 'utf8mb4', collation: 'utf8mb4_unicode_ci' do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :next_step, null: false, default: 'fan'
    end
  end
end
