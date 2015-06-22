mysql --login-path=greasyfork < /www/greasyfork/shellscripts/create_public_db.sql
mysqldump --login-path=greasyfork --single-transaction --quick greasyfork_public | gzip > /www/greasyfork/public/data/db.sql.gz
