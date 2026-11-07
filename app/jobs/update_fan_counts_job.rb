class UpdateFanCountsJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  SQL = <<~SQL.freeze # rubocop:disable Rails/SquishedSQLHeredocs
    # Find valid good/bad/ok ratings. Fans count as good. Remove people who rated themselves or rated twice.
    CREATE TEMPORARY TABLE fan_score (script_id BIGINT NOT NULL, fan_id BIGINT NOT NULL, score INT NOT NULL, UNIQUE script_fan (script_id, fan_id));
    # When a person has multiple signals for a script, the lowest priority number wins: good rating, bad rating, favorite, then ok rating.
    INSERT INTO fan_score (script_id, fan_id, score)
    SELECT script_id, fan_id, CASE MIN(priority) WHEN 1 THEN 1 WHEN 2 THEN -1 WHEN 3 THEN 1 WHEN 4 THEN 0 END
    FROM (
        SELECT script_id, poster_id AS fan_id, CASE Rating WHEN 4 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 4 END AS priority FROM discussions WHERE deleted_at IS NULL AND script_id IS NOT NULL AND Rating IN (2, 3, 4)
        UNION ALL
        SELECT child_id, user_id, 3 FROM script_sets JOIN script_set_script_inclusions ON script_sets.id = parent_id WHERE favorite
    ) candidates
    GROUP BY script_id, fan_id;

    # remove narcissists
    DELETE fan_score.*
        FROM fan_score
        JOIN scripts ON scripts.id = fan_score.script_id
        JOIN authors ON authors.script_id = scripts.id
    WHERE fan_id = authors.user_id;

    # Set good/bad counts for display
    UPDATE scripts SET good_ratings = 0, ok_ratings = 0, bad_ratings = 0;
    UPDATE scripts JOIN (SELECT script_id, COUNT(*) c FROM fan_score WHERE score = 1 GROUP BY script_id) a ON a.script_id = scripts.id SET good_ratings = a.c;
    UPDATE scripts JOIN (SELECT script_id, COUNT(*) c FROM fan_score WHERE score = 0 GROUP BY script_id) a ON a.script_id = scripts.id SET ok_ratings = a.c;
    UPDATE scripts JOIN (SELECT script_id, COUNT(*) c FROM fan_score WHERE score = -1 GROUP BY script_id) a ON a.script_id = scripts.id SET bad_ratings = a.c;

    # Aggregate the numbers. OK counts as 0.5 good, 0.5 bad
    CREATE TEMPORARY TABLE fan_aggregate (script_id BIGINT NOT NULL, positive DECIMAL(6,1) NOT NULL DEFAULT 0, negative DECIMAL(6,1) NOT NULL DEFAULT 0, UNIQUE script (script_id));
    INSERT INTO fan_aggregate (script_id, positive, negative) SELECT script_id, SUM(IF(score = 1, 1, IF(score = 0, 0.5, 0))), SUM(IF(score = -1, 1, IF(score = 0, 0.5, 0))) FROM fan_score GROUP BY script_id;

    # default score
    UPDATE scripts SET fan_score = 5;

    # "Lower bound of Wilson score confidence interval for a Bernoulli parameter" at 95% confidence.
    # Meaning "we're 95% sure that if everyone voted, the script would get at least this rating".
    # Multiply by 100 for nicer number.
    UPDATE scripts JOIN (SELECT script_id, ((positive + 1.9208) / (positive + negative) - 1.96 * SQRT((positive * negative) / (positive + negative) + 0.9604) / (positive + negative)) / (1 + 3.8416 / (positive + negative)) AS ci_lower_bound FROM fan_aggregate) a ON a.script_id = scripts.id SET fan_score = ci_lower_bound * 100;
  SQL

  # Does not reindex; update_install_counts does that as it finishes after this.
  def perform
    # Temporary tables are per-connection, so everything must run on one.
    ApplicationRecord.connection_pool.with_connection do |connection|
      statements.each { |statement| connection.execute(statement) }
    ensure
      connection.execute('DROP TEMPORARY TABLE IF EXISTS fan_score, fan_aggregate')
    end
  end

  private

  def statements
    SQL.lines.reject { |line| line.lstrip.start_with?('#') }.join.split(';').map(&:strip).compact_blank
  end
end
