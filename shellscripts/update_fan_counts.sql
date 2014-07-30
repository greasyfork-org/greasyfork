CREATE TEMPORARY TABLE fan_score (script_id INT NOT NULL, fan_id INT NOT NULL, score INT NOT NULL, UNIQUE script_fan (script_id, fan_id));
# good ratings
INSERT IGNORE INTO fan_score (script_id, fan_id, score) SELECT ScriptID, ForeignUserKey, 1 FROM GDN_Discussion JOIN GDN_UserAuthentication ON InsertUserID = UserID WHERE ScriptID IS NOT NULL AND Rating = 4;
# bad ratings
INSERT IGNORE INTO fan_score (script_id, fan_id, score) SELECT ScriptID, ForeignUserKey, -1 FROM GDN_Discussion JOIN GDN_UserAuthentication ON InsertUserID = UserID WHERE ScriptID IS NOT NULL AND Rating = 2;
# favorites
INSERT IGNORE INTO fan_score (script_id, fan_id, score) SELECT child_id, user_id, 1 FROM script_sets JOIN script_set_script_inclusions ON script_sets.id = parent_id WHERE favorite;
# remove narcissists
DELETE fan_score.* FROM fan_score JOIN scripts ON scripts.id = script_id WHERE fan_id = user_id;
UPDATE scripts SET fan_score = 0;
UPDATE scripts JOIN (SELECT script_id, SUM(score) s FROM fan_score GROUP BY script_id) a ON a.script_id = scripts.id SET fan_score = s;
