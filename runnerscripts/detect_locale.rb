Script.where(:locale_id => nil).find_each do |script|
	script.locale = script.detect_locale
	puts "#{script.id} #{script.name} is #{script.locale.nil? ? 'undetectable' : script.locale.code}"
	script.save(:validate => false) if !script.locale.nil?
end
