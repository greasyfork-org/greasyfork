applies_tos = {}
Script.where(:locked => false).find_each do |script|
	sv = script.get_newest_saved_script_version
	dcu = sv.disallowed_codes_used
	if !dcu.empty?
		puts "#{sv.script_id} #{dcu.inspect}"
	end
end

