# Log in information:
# - Uncomment it here (don't uncomment the require line), OR
# - Put in config/initializers/transifex.rb (including the require line)
#
# require 'transifex'
#
# Transifex.configure do |config|
#   config.username = 'your.username'
#   config.password = 'your.password'
# end

require 'transifex'
require 'yaml'

def lookup_value(h, dot_string)
	parts = dot_string.split('.')
	h = h[parts.first]
	return h if parts.length == 1 || h.nil?
	return lookup_value(h, parts[1..parts.length].join('.'))
end

project_slug = 'greasy-fork'

transifex = Transifex::Client.new
project = transifex.project(project_slug)
rails_resource = project.resource('enyml-19')

vanilla_resource = project.resource('defaultphp')
vanilla_locale_maps = {
  'zh_CN' => 'zh',
}

english_content = YAML.load_file('config/locales/en.yml')['en']

LocaleContributor.delete_all

project.languages.each do |language|
	code = language.language_code
	code_with_hyphens = code.sub('_', '-')
	puts "Getting locale #{code_with_hyphens}"
	locale = Locale.where(:code => code_with_hyphens).first
	if locale.nil?
		puts "Unknown locale #{code_with_hyphens}, skipping"
		next
	end
	(language.coordinators + language.reviewers + language.translators).each do |contributor|
		LocaleContributor.create({:locale => locale, :transifex_user_name => contributor})
	end
	locale.percent_complete = rails_resource.stats(code).completed.to_i
	locale.save!
	if Greasyfork::Application.config.download_locale_files
		# write Rails file
		c = rails_resource.translation(code).content
		# transifex likes underscores in locale names, we like hyphens
		c.sub!(code, code_with_hyphens) if code != code_with_hyphens
		File.open("config/locales/#{code_with_hyphens}.yml", 'w') { |file| file.write(c) }

		# write Vanilla file
		vanilla_filename = vanilla_locale_maps[code]
		vanilla_filename = code if vanilla_filename.nil?
		File.open("misc/vanilla-plugin/locale/#{vanilla_filename}.php", 'w') { |file| file.write(vanilla_resource.translation(code).content) }

		# write Vanilla file for things already in Rails
		translated_content = YAML.load(c)[code_with_hyphens]
		File.open("misc/vanilla-theme/locale/#{vanilla_filename}.php", 'w') { |file|
			file.write("<?php\n")
			['layouts.application.script_list', 'layouts.application.forum', 'layouts.application.help', 'layouts.application.search'].each do |k|
				v = lookup_value(translated_content, k)
				v = lookup_value(english_content, k) if v.nil?
				raise "not found #{k}" if v.nil?
				file.write("$Definition['#{k}'] = '#{v}';\n")
			end
		}
	end
end
