applies_tos = {}
Script.find_each do |script|
	sv = script.get_newest_saved_script_version
	sv.do_lenient_saving
	sv.calculate_all(script.description)
	script.apply_from_script_version(sv)
	puts "#{script.id} script validation errors: #{script.errors.full_messages.join(', ')}" if !script.valid?
	puts "#{script.id} script version validation errors: #{sv.errors.full_messages.join(', ')}" if !sv.valid?
	begin
		script.save(:validate => false)
		sv.save(:validate => false)
	rescue Exception => ex
		puts "#{script.id} not saved - #{ex}"
	else
		puts "#{script.id} saved"
	end
end

