#!/bin/bash

MAILTO="jason.barnabe@gmail.com"

echo "Starting at `date`" >> ../log/update_install_counts.log
mysql < ./update_install_counts.sql >> ../log/update_install_counts.log 2>&1
echo "Reindexing scripts at `date`" >> ../log/update_install_counts.log
RAILS_ENV=production CLASS=Script /home/deploy/.rbenv/bin/rbenv exec bundle exec rails runner 'Script.reindex' >> ../log/update_install_counts.log 2>&1
echo "Reindexing users at `date`" >> ../log/update_install_counts.log
# We could just do User.script_authors.reindex but we should reindex everyone in case other updates got missed.
RAILS_ENV=production CLASS=User /home/deploy/.rbenv/bin/rbenv exec bundle exec rails runner 'User.reindex' >> ../log/update_install_counts.log 2>&1
echo "Done at `date`" >> ../log/update_install_counts.log
