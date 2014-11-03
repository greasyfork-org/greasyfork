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

project_slug = 'greasy-fork'
resource_slug = 'enyml-19'

transifex = Transifex::Client.new
project = transifex.project(project_slug)
resource = project.resource(resource_slug)

LocaleContributor.delete_all

project.languages.each do |language|
	code = language.language_code
	code_with_hyphens = code.sub('_', '-')
	puts "Getting locale #{code_with_hyphens}"
	locale = Locale.where(:code => code_with_hyphens).first
	(language.coordinators + language.reviewers + language.translators).each do |contributor|
		LocaleContributor.create({:locale => locale, :transifex_user_name => contributor})
	end
	locale.percent_complete = resource.stats(code).completed.to_i
	locale.save!
	if Greasyfork::Application.config.download_locale_files
		c = resource.translation(code).content
		# transifex likes underscores in locale names, we like hyphens
		c.sub!(code, code_with_hyphens) if code != code_with_hyphens
		File.open("config/locales/#{code_with_hyphens}.yml", 'w') { |file| file.write(c) }
	end
end
