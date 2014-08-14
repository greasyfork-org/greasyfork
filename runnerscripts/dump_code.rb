Script.find_each do |script|
	code = script.get_newest_saved_script_version.code
	if code.length < 100000
		File.open("tmp/cpd/#{script.id}.js", 'w') { |file| file.write(code) }
	end
end
