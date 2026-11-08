class UpdateInstallCounts
  BATCH_SIZE = 500

  def perform
    ApplicationRecord.connection_pool.with_connection do |connection|
      cutoffs = ScriptStatsTiming.measure('UpdateInstallCounts select cutoffs') do
        connection.select_one('SELECT NOW() AS run_time, DATE_SUB(NOW(), INTERVAL 1 DAY) AS daily_cutoff, DATE_SUB(CURDATE(), INTERVAL 1 DAY) AS historical_cutoff')
      end

      begin
        ScriptStatsTiming.measure('UpdateInstallCounts prepare historical counts') { prepare_historical_counts(connection) }
        ScriptStatsTiming.measure('UpdateInstallCounts delete banned installs') { delete_banned_installs(connection, cutoffs.fetch('run_time')) }

        ScriptStatsTiming.measure('UpdateInstallCounts process batches') do
          Script.select(:id).find_in_batches(batch_size: BATCH_SIZE) do |scripts|
            first_id = scripts.first.id
            last_id = scripts.last.id
            batch = "UpdateInstallCounts batch #{first_id}-#{last_id}"
            ScriptStatsTiming.measure(batch) do
              connection.transaction(requires_new: true) do
                # The historical snapshot predates this batch's rollup.
                ScriptStatsTiming.measure("#{batch} update script counts") { update_script_counts(connection, first_id, last_id, cutoffs.fetch('daily_cutoff')) }
                ScriptStatsTiming.measure("#{batch} roll up installs") { roll_up_installs(connection, first_id, last_id, cutoffs.fetch('historical_cutoff')) }
              end
            end
          end
        end
      ensure
        ScriptStatsTiming.measure('UpdateInstallCounts drop temporary table') { connection.execute('DROP TEMPORARY TABLE IF EXISTS install_count_totals') }
      end
    end

    ScriptStatsTiming.measure('UpdateInstallCounts reindex') { Script.reindex(:install_counts_search_data, scope: :indexable, ignore_missing: true) }
  end

  private

  def prepare_historical_counts(connection)
    ScriptStatsTiming.measure('UpdateInstallCounts create historical totals table') do
      connection.execute('CREATE TEMPORARY TABLE install_count_totals (script_id BIGINT NOT NULL PRIMARY KEY, total BIGINT NOT NULL)')
    end
    # A plain SELECT avoids locking historical rows while aggregating them.
    counts = ScriptStatsTiming.measure('UpdateInstallCounts select historical totals') do
      connection.select_rows(<<~SQL.squish)
        SELECT script_id, SUM(installs)
        FROM install_counts IGNORE INDEX (index_install_counts_on_script_id_and_install_date)
        GROUP BY script_id
      SQL
    end
    ScriptStatsTiming.measure('UpdateInstallCounts insert historical totals') do
      counts.each_slice(BATCH_SIZE) do |batch|
        values = batch.map { |script_id, total| "(#{Integer(script_id)}, #{Integer(total)})" }.join(', ')
        connection.execute("INSERT INTO install_count_totals (script_id, total) VALUES #{values}")
      end
    end
  end

  def delete_banned_installs(connection, current_time)
    connection.execute(<<~SQL.squish)
      DELETE daily_install_counts FROM daily_install_counts
      JOIN stat_bans ON stat_bans.script_id = daily_install_counts.script_id
      WHERE stat_bans.expires_at > #{connection.quote(current_time)}
    SQL
  end

  def roll_up_installs(connection, first_id, last_id, historical_cutoff)
    cutoff = connection.quote(historical_cutoff)
    batch = "UpdateInstallCounts batch #{first_id}-#{last_id}"
    ScriptStatsTiming.measure("#{batch} insert rollups") do
      connection.execute(<<~SQL.squish)
        INSERT INTO install_counts (script_id, install_date, installs)
        SELECT script_id, DATE(install_date), COUNT(*)
        FROM daily_install_counts
        WHERE script_id BETWEEN #{first_id} AND #{last_id} AND install_date < #{cutoff}
        GROUP BY script_id, DATE(install_date)
        ON DUPLICATE KEY UPDATE installs = installs + VALUES(installs)
      SQL
    end
    ScriptStatsTiming.measure("#{batch} delete rolled-up installs") do
      connection.execute(<<~SQL.squish)
        DELETE FROM daily_install_counts
        WHERE script_id BETWEEN #{first_id} AND #{last_id} AND install_date < #{cutoff}
      SQL
    end
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
      LEFT JOIN install_count_totals h ON h.script_id = s.id
      SET s.daily_installs = COALESCE(d.daily, 0),
          s.total_installs = COALESCE(d.total, 0) + COALESCE(h.total, 0)
      WHERE s.id BETWEEN #{first_id} AND #{last_id}
        AND (s.daily_installs <> COALESCE(d.daily, 0)
          OR s.total_installs <> COALESCE(d.total, 0) + COALESCE(h.total, 0))
    SQL
  end
end
