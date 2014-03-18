require 'test_helper'
require 'script_importer/url_importer'
require 'script_importer/script_syncer'
include ScriptImporter

class ScriptSyncerTest < ActiveSupport::TestCase

	test 'sync' do
		script = Script.find(7)
		assert_equal 1, script.script_versions.length
		assert_equal :success, ScriptSyncer.sync(script)
		assert_equal 'A Test!', script.name
		assert_equal Time.now.utc.to_date, script.code_updated_at.to_date
		assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
		assert_equal Time.now.utc.to_date, script.last_successful_sync_date.to_date
		assert_nil script.sync_error
		assert_equal 2, script.script_versions.length
	end

	test 'unchanged' do
		script = Script.find(8)
		assert_equal 1, script.script_versions.length
		assert_equal :unchanged, ScriptSyncer.sync(script)
		assert_equal '2000-01-01', script.code_updated_at.to_date.to_s
		assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
		assert_equal Time.now.utc.to_date, script.last_successful_sync_date.to_date
		assert_nil script.sync_error
		assert_equal 1, script.script_versions.length
	end

	test 'keep old description' do
		script = Script.find(9)
		assert_equal 1, script.script_versions.length
		assert_equal :success, ScriptSyncer.sync(script), script.sync_error
		assert_equal Time.now.utc.to_date, script.code_updated_at.to_date.to_date
		assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
		assert_equal Time.now.utc.to_date, script.last_successful_sync_date.to_date
		assert_nil script.sync_error
		assert_equal 'Unit test.', script.description
		assert_equal 2, script.script_versions.length
		assert_equal :unchanged, ScriptSyncer.sync(script)
		assert_equal 2, script.script_versions.length
	end

	test 'new version invalid' do
		script = Script.find(10)
		assert_equal 1, script.script_versions.length
		assert_equal :failure, ScriptSyncer.sync(script)
		assert_equal '2000-01-01', script.code_updated_at.to_date.to_s
		assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
		assert_equal '2000-01-01', script.last_successful_sync_date.to_date.to_s
		assert_not_nil script.sync_error
		assert_equal 1, script.script_versions.length
	end

	test 'keep old additional info' do
		script = Script.find(7)
		assert_equal 1, script.script_versions.length
		assert_equal :success, ScriptSyncer.sync(script), script.sync_error
		assert_equal 2, script.script_versions.length
		assert_equal 'MyText', script.script_versions.last.additional_info
		assert_equal 'MyText', script.additional_info
		assert_equal 'markdown', script.script_versions.last.additional_info_markup
		assert_equal 'markdown', script.additional_info_markup
	end

end
