mysql --login-path=greasyfork < $(dirname $0)/create_public_db.sql
mysqldump --login-path=greasyfork --single-transaction --quick greasyfork_public | gzip > $(dirname $0)/../public/data/db.sql.gz
