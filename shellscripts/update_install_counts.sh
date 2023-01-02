#!/bin/bash

MAILTO="jason.barnabe@gmail.com"

echo "Starting at `date`" >> ../log/update_install_counts.log
mysql < ./update_install_counts.sql >> ../log/update_install_counts.log 2>&1
echo "Reindexing at `date`" >> ../log/update_install_counts.log
RAILS_ENV=production /home/deploy/.rbenv/bin/rbenv exec bundle exec rake ts:index >> ../log/update_install_counts.log 2>&1
echo "Done at `date`" >> ../log/update_install_counts.log
