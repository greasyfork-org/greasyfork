echo "Starting at `date`" >> ../log/update_install_counts.log
mysql < ./update_install_counts.sql >> ../log/update_install_counts.log 2>&1
echo "Done at `date`" >> ../log/update_install_counts.log
