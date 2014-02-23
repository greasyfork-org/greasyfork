applies_tos = {}
Script.find_each do |script|
	script.script_versions.last.calculate_applies_to_names.each do |at|
		if applies_tos.has_key?(at)
			applies_tos[at] << script.id
		else
			applies_tos[at] = [script.id]
		end
	end
end
applies_tos.sort_by { |name, script_id_array| script_id_array.length }.reverse.each do |name, script_id_array|
	puts name + ' ' + script_id_array.inspect
end
