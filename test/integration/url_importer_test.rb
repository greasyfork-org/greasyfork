require 'test_helper'
require 'script_importer/url_importer'
include ScriptImporter

class UrlImporterTest < ActiveSupport::TestCase

	test 'generate script' do
		result, script, message = UrlImporter.generate_script('https://github.com/scintill/userscripts/raw/master/routey-on-home.user.js', nil, User.find(1))
		assert_equal :success, result, message
		assert_not_nil script
		assert_equal 'Route Y links on the BYU Home Page', script.name
		assert_equal 'https://github.com/scintill/userscripts/raw/master/routey-on-home.user.js', script.sync_identifier
		assert_equal '1', script.script_sync_source_id.to_s
	end

end
