#!/bin/bash

MAILTO="jason.barnabe@gmail.com"

echo "Starting at `date`" >> ../log/update_fan_counts.log
mysql < ./update_fan_counts.sql >> ../log/update_fan_counts.log 2>&1
# Should also reindex after this, but we let update_install_counts.sh do it as it finishes after us.
echo "Done at `date`" >> ../log/update_fan_counts.log
