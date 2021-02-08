echo "Starting at `date`" >> ../log/update_counts_from_log.log

grep -Fh "`date +'%Y-%m-%dT%H' -d '1 hour ago'`" `ls -tr1 /var/log/nginx/metajs.log* | tail -2` |\
grep -E " (200|304) GET " |\
cut -d" " -f1,2,5 |\
awk '{ print gensub(/.*scripts\/([0-9]+).*/, "\\1", "g", $3), $1, $2 }' |\
grep -E '^[0-9]+.* [T:\+0-9\-]{25} [0-9\.]{7,}$' |\
sed 's/\+[0-9][0-9]:[0-9][0-9]//' > /tmp/daily_update_check_counts.txt

echo "Loading daily update counts into DB at `date`" >> ../log/update_counts_from_log.log

mysqlimport --local --fields-terminated-by=" " --ignore greasyfork /tmp/daily_update_check_counts.txt >> ../log/update_counts_from_log.log 2>&1

echo "Done at `date`" >> ../log/update_counts_from_log.log
