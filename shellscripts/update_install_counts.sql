-- daily installs - anything in the last 24 hours
UPDATE scripts SET daily_installs = 0;
UPDATE scripts s
  JOIN (
    SELECT script_id, COUNT(*) c FROM daily_install_counts WHERE install_date >= DATE_SUB(NOW(), INTERVAL 1 DAY) GROUP BY script_id
  ) d
  ON s.id = d.script_id
  SET s.daily_installs = d.c;

-- move anything before yesterday to the historical count table
INSERT IGNORE INTO install_counts
  (script_id, install_date, installs)
  (SELECT script_id, DATE(install_date), COUNT(*) FROM daily_install_counts WHERE install_date < DATE_SUB(CURDATE(), INTERVAL 1 DAY) GROUP BY script_id, DATE(install_date));
DELETE FROM daily_install_counts WHERE install_date < DATE_SUB(CURDATE(), INTERVAL 1 DAY);

-- update total installs to be the sum of installs from historical and daily
CREATE TEMPORARY TABLE total_install_counts (script_id int PRIMARY KEY NOT NULL, c INTEGER NOT NULL);
INSERT INTO total_install_counts (script_id, c) SELECT script_id, SUM(installs) c FROM install_counts GROUP BY script_id;
INSERT INTO total_install_counts (script_id, c) SELECT * FROM (SELECT script_id, COUNT(*) daily_count FROM daily_install_counts GROUP BY script_id) dic ON DUPLICATE KEY UPDATE c = c + daily_count;
UPDATE scripts LEFT JOIN total_install_counts on id = script_id set total_installs = IFNULL(c, 0);

-- for update counts, we want to deal with what happened last hour (as this runs at the top of the hour)
-- update update counts for last hour's date
INSERT INTO update_check_counts
  (script_id, update_check_date, update_checks)
  (SELECT script_id, DATE(update_date), COUNT(*) c FROM daily_update_check_counts WHERE DATE(update_date) = DATE(DATE_SUB(NOW(), INTERVAL 1 HOUR)) GROUP BY script_id, DATE(update_date)) ON DUPLICATE KEY UPDATE update_checks = VALUES(update_checks);
-- clear out anything older than 1 day so that new things are not considered duplicates
DELETE FROM daily_update_check_counts WHERE update_date < DATE_SUB(NOW(), INTERVAL 1 DAY);
