echo "Clearing files at `date`"
mkdir -p tmp/cpd
rm -f tmp/cpd/*
echo "Dumping files at `date`"
rails runner runnerscripts/dump_code.rb
echo "Running CPD at `date`"
shellscripts/run_cpd.sh
echo "Parsing CPD results at `date`"
rails runner runnerscripts/parse_cpd_results.rb
echo "Done at `date`"
