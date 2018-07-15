find /www/greasyfork/shared/tmp/cached_pages/ -mmin +60 -type f -delete 2>/dev/null
find /www/greasyfork/shared/tmp/cached_pages/ -mindepth 1 -type d -empty -delete 2>/dev/null
