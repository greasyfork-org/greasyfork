#!/bin/bash

MAILTO="jason.barnabe@gmail.com"
PATH="/www/sphinx-3.3.1/bin:$PATH"

echo "Starting at `date`" >> ../log/update_install_counts.log
mysql < ./update_install_counts.sql >> ../log/update_install_counts.log 2>&1
echo "Reindexing scripts at `date`" >> ../log/update_install_counts.log
RAILS_ENV=production INDEX_FILTER=script_core /home/deploy/.rbenv/bin/rbenv exec bundle exec rake ts:index >> ../log/update_install_counts.log 2>&1
RAILS_ENV=production CLASS=Script /home/deploy/.rbenv/bin/rbenv exec bundle exec rails runner 'Script.reindex' >> ../log/update_install_counts.log 2>&1
echo "Reindexing users at `date`" >> ../log/update_install_counts.log
RAILS_ENV=production CLASS=User /home/deploy/.rbenv/bin/rbenv exec bundle exec rails runner 'User.script_authors.reindex' >> ../log/update_install_counts.log 2>&1
echo "Done at `date`" >> ../log/update_install_counts.log
