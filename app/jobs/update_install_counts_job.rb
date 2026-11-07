class UpdateInstallCountsJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log

  sidekiq_retries_exhausted do |job, _exception|
    SidekiqUniqueJobs::Digests.new.delete_by_digest(job.fetch('lock_digest'))
  end

  BATCH_SIZE = 500

  def perform
    ApplicationRecord.connection_pool.with_connection do |connection|
      cutoffs = connection.select_one('SELECT NOW() AS run_time, DATE_SUB(NOW(), INTERVAL 1 DAY) AS daily_cutoff, DATE_SUB(CURDATE(), INTERVAL 1 DAY) AS historical_cutoff')

      Script.select(:id).find_in_batches(batch_size: BATCH_SIZE) do |scripts|
        first_id = scripts.first.id
        last_id = scripts.last.id
        connection.transaction(requires_new: true) do
          delete_banned_installs(connection, first_id, last_id, cutoffs.fetch('run_time'))
          roll_up_installs(connection, first_id, last_id, cutoffs.fetch('historical_cutoff'))
          update_script_counts(connection, first_id, last_id, cutoffs.fetch('daily_cutoff'))
        end
      end
    end

    Script.reindex
  end

  private

  def delete_banned_installs(connection, first_id, last_id, current_time)
    connection.execute(<<~SQL.squish)
      DELETE daily_install_counts FROM daily_install_counts
      JOIN stat_bans ON stat_bans.script_id = daily_install_counts.script_id
      WHERE daily_install_counts.script_id BETWEEN #{first_id} AND #{last_id}
        AND stat_bans.expires_at > #{connection.quote(current_time)}
    SQL
  end

  def roll_up_installs(connection, first_id, last_id, historical_cutoff)
    cutoff = connection.quote(historical_cutoff)
    connection.execute(<<~SQL.squish)
      INSERT INTO install_counts (script_id, install_date, installs)
      SELECT script_id, DATE(install_date), COUNT(*)
      FROM daily_install_counts
      WHERE script_id BETWEEN #{first_id} AND #{last_id} AND install_date < #{cutoff}
      GROUP BY script_id, DATE(install_date)
      ON DUPLICATE KEY UPDATE installs = installs + VALUES(installs)
    SQL
    connection.execute(<<~SQL.squish)
      DELETE FROM daily_install_counts
      WHERE script_id BETWEEN #{first_id} AND #{last_id} AND install_date < #{cutoff}
    SQL
  end

  def update_script_counts(connection, first_id, last_id, daily_cutoff)
    connection.execute(<<~SQL.squish)
      UPDATE scripts s
      LEFT JOIN (
        SELECT script_id, COUNT(*) AS total, SUM(install_date >= #{connection.quote(daily_cutoff)}) AS daily
        FROM daily_install_counts
        WHERE script_id BETWEEN #{first_id} AND #{last_id}
        GROUP BY script_id
      ) d ON d.script_id = s.id
      LEFT JOIN (
        SELECT script_id, SUM(installs) AS total
        FROM install_counts
        WHERE script_id BETWEEN #{first_id} AND #{last_id}
        GROUP BY script_id
      ) h ON h.script_id = s.id
      SET s.daily_installs = COALESCE(d.daily, 0),
          s.total_installs = COALESCE(d.total, 0) + COALESCE(h.total, 0)
      WHERE s.id BETWEEN #{first_id} AND #{last_id}
        AND (s.daily_installs <> COALESCE(d.daily, 0)
          OR s.total_installs <> COALESCE(d.total, 0) + COALESCE(h.total, 0))
    SQL
  end
end
