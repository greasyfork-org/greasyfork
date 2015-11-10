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
UPDATE scripts s
  LEFT JOIN (
    SELECT script_id, SUM(installs) c FROM install_counts GROUP BY script_id
  ) h
  ON s.id = h.script_id
  LEFT JOIN (
    SELECT script_id, COUNT(*) c FROM daily_install_counts GROUP BY script_id
  ) d  
  ON s.id = d.script_id
  SET s.total_installs = IFNULL(h.c, 0) + IFNULL(d.c, 0);

-- update checks - move anything before yesterday to the historical count table
INSERT IGNORE INTO update_check_counts
  (script_id, update_check_date, update_checks)
  (SELECT script_id, DATE(update_check_date), COUNT(*) FROM daily_update_check_counts WHERE update_check_date < DATE_SUB(CURDATE(), INTERVAL 1 DAY) GROUP BY script_id, DATE(update_check_date));
DELETE FROM daily_update_check_counts WHERE update_check_date < DATE_SUB(CURDATE(), INTERVAL 1 DAY);
