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

translations_to_download = ['de', 'id', 'ja', 'nl', 'ru', 'zh-CN', 'zh-TW']
project_slug = 'greasy-fork'
resource_slug = 'enyml-19'

transifex = Transifex::Client.new
project = transifex.project(project_slug)
resource = project.resource(resource_slug)
translations_to_download.each do |t|
	puts "Getting locale #{t}"
	c = resource.translation(t).content
	# transifex likes underscores in locale names, we like hyphens
	c.sub!(t.sub('-', '_'), t) if t.include?('-')
	File.open("config/locales/#{t}.yml", 'w') { |file| file.write(c) }
end
