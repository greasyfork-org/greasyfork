find /home/www/greasyfork/shared/tmp/cached_pages/ -mmin +60 -type f -delete
find /home/www/greasyfork/shared/tmp/cached_pages/ -mindepth 1 -type d -empty -delete
#find /home/www/greasyfork/shared/tmp/cached_pages/ -mmin +10 -type f -delete
#find /home/www/greasyfork/shared/tmp/cached_pages/ -mindepth 1 -type d -empty -delete
