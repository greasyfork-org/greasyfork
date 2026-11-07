#!/bin/bash
set -o pipefail

cd "$(dirname "$0")" || exit 1
LOG=../log/update_counts_from_log.log

echo "Starting at `date`" >> $LOG

# mariadb-import derives the table name from the file's basename.
WORK_DIR=`mktemp -d` || exit 1
trap 'rm -rf "$WORK_DIR"' EXIT
DATA_FILE="$WORK_DIR/daily_update_check_counts.txt"

HOUR=`date -u +'%Y-%m-%dT%H' -d '1 hour ago'`

# Log lines look like: <timestamp> <ip> <status> GET <url> ... Output is: <script id> <timestamp> <ip>, one per script and IP.
ls -tr1 /var/log/nginx/metajs.log* | grep -v '\.gz$' | tail -2 | xargs awk -v hour="$HOUR" '
  substr($1, 1, 13) != hour { next }
  $3 !~ /^(200|304)$/ || $4 != "GET" { next }
  $1 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+00:00$/ { next }
  $2 !~ /^[0-9a-fA-F:.]+$/ || length($2) > 45 || $2 !~ /[.:]/ { next }
  !match($5, /scripts\/[0-9]+/) { next }
  {
    id = substr($5, RSTART + 8, RLENGTH - 8)
    if (seen[id, $2]++) next
    print id, substr($1, 1, 19), $2
  }
' > "$DATA_FILE"
if [ $? -ne 0 ]; then
  echo "Failed to extract counts from nginx logs at `date`" >> $LOG
  exit 1
fi

echo "Loading daily update counts into DB at `date`" >> $LOG

mariadb-import --local --fields-terminated-by=" " --columns=script_id,update_date,ip --ignore greasyfork "$DATA_FILE" >> $LOG 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to load into DB at `date`" >> $LOG
  exit 1
fi

echo "Done at `date`" >> $LOG
