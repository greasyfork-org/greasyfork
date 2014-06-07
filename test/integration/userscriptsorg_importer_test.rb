require 'test_helper'
require 'script_importer/userscriptsorg_importer'
include ScriptImporter

class UserscriptsorgImporterTest < ActiveSupport::TestCase

	test 'remote user identifier' do
		skip('userscripts.org down')
		assert_equal '4630', UserScriptsOrgImporter.remote_user_identifier('http://userscripts.org/users/4630')
	end

	test 'verify user' do
		skip('userscripts.org down')
		assert_equal :success, UserScriptsOrgImporter.verify_ownership('http://userscripts.org/users/4630', 1)
	end

	test 'verify user no url' do
		skip('userscripts.org down')
		assert_equal :nourl, UserScriptsOrgImporter.verify_ownership('http://userscripts.org/users/1', 1)
	end

	test 'pull script list' do
		skip('userscripts.org down')
		new_scripts, existing_scripts = UserScriptsOrgImporter.pull_script_list('http://userscripts.org/users/4630')
		assert existing_scripts.empty?
		assert new_scripts.length > 1
		assert new_scripts.has_key?(22356), new_scripts.inspect
		assert_equal 'Hotmail login fix', new_scripts[22356][:name]
		assert_equal "#{Greasyfork::Application.config.userscriptsorg_host}/scripts/source/22356.user.js", new_scripts[22356][:url]
	end

	test 'pull script list with existing' do
		skip('userscripts.org down')
		previous_script = get_valid_script
		previous_script.script_sync_source_id = '2'
		previous_script.sync_identifier = '22356'
		previous_script.save!

		new_scripts, existing_scripts = UserScriptsOrgImporter.pull_script_list('http://userscripts.org/users/4630')
		assert !existing_scripts.empty?
		assert_equal 1, existing_scripts.length
	end

	test 'generate script' do
		skip('userscripts.org down')
		result, script, message = UserScriptsOrgImporter.generate_script('22356', nil, User.find(1))
		assert_equal :success, result
		assert_not_nil script
		assert_equal 'Hotmail', script.name
		assert_equal 'Works around the "have to log in twice for msn.com e-mail addresses" bug https://bugzilla.mozilla.org/show_bug.cgi?id=415310', script.description
		assert_equal '22356', script.sync_identifier
		assert_equal '2', script.script_sync_source_id.to_s
	end

	test 'generate script bad id' do
		skip('userscripts.org down')
		result, script, message = UserScriptsOrgImporter.generate_script('31415926', nil, User.find(1))
		assert_equal :failure, result
	end

	test 'generate script no description' do
		skip('userscripts.org down')
		result, script, message = UserScriptsOrgImporter.generate_script('411774', nil, User.find(1))
		assert_equal :needsdescription, result
	end

	test 'generate script no description provided description' do
		skip('userscripts.org down')
		description = 'This is the description'
		result, script, message = UserScriptsOrgImporter.generate_script('411774', description, User.find(1))
		assert_equal :success, result
		assert_equal description, script.description
	end

	test 'generate script validation fail' do
		skip('userscripts.org down')
		result, script, message = UserScriptsOrgImporter.generate_script('411783', nil, User.find(1))
		assert !script.valid?
		assert_equal :failure, result
	end

end
