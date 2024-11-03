# Find all ids/timestamps where the code has been updated in the last 5 minutes. Find all matching files in the 'latest'
# folders where the modification date is before the DB value and delete them.
#
# - We go 1 second back on the DB value to avoid deleting exact matches, as we're inverting newermt which is a >,
#   turning the comparison in to a <=.
# - We do the last 5 minutes instead of 1 so we don't miss something if the server restarts.
echo "select id, DATE_SUB(code_updated_at, INTERVAL 1 SECOND) from scripts where code_updated_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE);" | \
mysql --skip-column-names | \
awk 'BEGIN {FS="\t"};{ system("find /www/greasyfork/shared/tmp/cached_code/*/latest/scripts/" $1 ".* -type f ! -newermt \"" $2 " UTC\" -delete") }' 2> /dev/null

# Delete anything with a ctime (which is create time for our purposes) over a day old, just in case we missed something
# above, and also to clear out any deleted or rarely-accessed files.
find /www/greasyfork/shared/public/cached_code/ -cmin +1440 -type f -delete 2>/dev/null
find /www/greasyfork/shared/public/cached_code_404/ -cmin +1440 -type f -delete 2>/dev/null