Script.includes(:script_applies_tos).find_each do |script|
  sv = script.newest_saved_script_version
  sv.do_lenient_saving
  sv.calculate_all(script.description)
  script.apply_from_script_version(sv)
  puts "#{script.id} script validation errors: #{script.errors.full_messages.join(', ')}" unless script.valid?
  puts "#{script.id} script version validation errors: #{sv.errors.full_messages.join(', ')}" unless sv.valid?
  begin
    script.save(validate: false)
    sv.save(validate: false)
  rescue StandardError => e
    puts "#{script.id} not saved - #{e}"
  else
    puts "#{script.id} saved"
  end
end
