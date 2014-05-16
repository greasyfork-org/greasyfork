applies_tos = {}
Script.find_each do |script|
	script.script_applies_tos = script.script_versions.last.calculate_applies_to_names.map do |pattern, name|
		ScriptAppliesTo.new({:pattern => pattern, :display_text => name})
	end
	script.save(:validate => false)
	puts "Saved #{script.id}"
end

