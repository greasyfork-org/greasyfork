#!/bin/bash

MAILTO="jason.barnabe@gmail.com"

if [ -e /www/greasyfork/shared/db/sphinx/production/ts-script_delta.tmp ] && test `find "/www/greasyfork/shared/db/sphinx/production/ts-script_delta.tmp" -mmin +10`
then
    echo "Old index file found. Deleting and reindexing."
    rm /www/greasyfork/shared/db/sphinx/production/ts-script_delta.tmp
    cd /www/greasyfork/current
    RAILS_ENV=production /home/deploy/.rbenv/bin/rbenv exec bundle exec rake ts:index
fi
