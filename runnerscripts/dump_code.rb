Script.find_each do |script|
	# use rewritten code as that's what we can link to to show the user
	code = script.get_newest_saved_script_version.rewritten_code
	if code.length < Rails.configuration.cpd_size_limit
		File.open("tmp/cpd/#{script.id}.js", 'w') { |file| file.write(code) }
	end
end
