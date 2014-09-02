results = File.read('tmp/cpd/results.csv')

if results.empty?
	puts "Results is empty, skipping parsing."
else
	CpdDuplication.delete_all
	CpdDuplicationScript.delete_all

	results.each_line do |line|
		# skip header and blank last line
		next if line.starts_with?('lines') or line.blank?
		fields = line.split(',')
		c = CpdDuplication.new({:lines => fields[0]})
		i = 3
		while i < fields.length
			script_id = fields[i+1].split('/').last.split('.').first
			c.cpd_duplication_scripts << CpdDuplicationScript.new({:line => fields[i], :script_id => script_id})
			i += 2
		end
		c.save
	end
end
