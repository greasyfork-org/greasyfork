require 'test_helper'

class UsersControllerTest < ActionController::TestCase

	test 'get_synced_scripts empty' do
		assert_empty UsersController.get_synced_scripts(User.first, {})
	end

	test 'get_synced_scripts single' do
		scripts_and_messages = UsersController.get_synced_scripts(User.first, {'http://www.example.com/sync' => ['commit message']})
		assert_equal 1, scripts_and_messages.length
		assert_equal 1, scripts_and_messages.values.first.length, scripts_and_messages.values.first
		assert_equal 'commit message', scripts_and_messages.values.first.first
	end

	test 'get_synced_scripts single no match' do
		scripts_and_messages = UsersController.get_synced_scripts(User.first, {'http://www.example.com/stync' => ['commit message']})
		assert_empty scripts_and_messages
	end

	test 'get_synced_scripts multiple messages' do
		scripts_and_messages = UsersController.get_synced_scripts(User.first, {'http://www.example.com/sync' => ['commit message 1', 'commit message 2']})
		assert_equal 1, scripts_and_messages.length
		assert_equal 2, scripts_and_messages.values.first.length, scripts_and_messages.values.first
	end

	test 'get_synced_scripts repeated message' do
		scripts_and_messages = UsersController.get_synced_scripts(User.first, {'http://www.example.com/sync' => ['commit message', 'commit message']})
		assert_equal 1, scripts_and_messages.length
		assert_equal 1, scripts_and_messages.values.first.length, scripts_and_messages.values.first
	end

	test 'get_synced_scripts ai' do
		scripts_and_messages = UsersController.get_synced_scripts(User.first, {'http://www.example.com/ai/sync' => ['commit message']})
		assert_equal 1, scripts_and_messages.length
		assert_equal 1, scripts_and_messages.values.first.length, scripts_and_messages.values.first
		assert_equal 'commit message', scripts_and_messages.values.first.first
	end

end
