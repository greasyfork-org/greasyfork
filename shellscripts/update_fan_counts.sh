echo "Starting at `date`" >> ../log/update_fan_counts.log
mysql < ./update_fan_counts.sql >> ../log/update_fan_counts.log 2>&1
echo "Done at `date`" >> ../log/update_fan_counts.log
