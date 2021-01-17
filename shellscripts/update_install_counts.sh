echo "Starting at `date`" >> ../log/update_install_counts.log
mysql --login-path=greasyfork greasyfork < ./update_install_counts.sql >> ../log/update_install_counts.log 2>&1
echo "Done at `date`" >> ../log/update_install_counts.log
