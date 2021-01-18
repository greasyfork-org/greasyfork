-- for update counts, we want to deal with what happened last hour (as this runs at the top of the hour)
-- update update counts for last hour's date
INSERT INTO update_check_counts
  (script_id, update_check_date, update_checks)
  (SELECT script_id, DATE(update_date), COUNT(*) c FROM daily_update_check_counts WHERE DATE(update_date) = DATE(DATE_SUB(NOW(), INTERVAL 1 HOUR)) GROUP BY script_id, DATE(update_date)) ON DUPLICATE KEY UPDATE update_checks = VALUES(update_checks);
-- clear out anything older than 1 day so that new things are not considered duplicates
DELETE FROM daily_update_check_counts WHERE update_date < DATE_SUB(NOW(), INTERVAL 1 DAY);
