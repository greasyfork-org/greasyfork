ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'minitest/autorun'
require 'mocha/minitest'
require 'application_system_test_case'

module ActiveSupport
  class TestCase
    ActiveRecord::Migration.check_pending!

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    #
    # Note: You'll currently still have to declare fixtures explicitly in integration tests
    # -- they do not yet inherit this setting
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def valid_script
      script = Script.new
      script_version = ScriptVersion.new
      script.script_versions << script_version
      script_version.script = script
      script_version.version = '123'

      script_version.code = <<~JS
        // ==UserScript==
        // @name		A Test!
        // @description		Unit test.
        // @namespace http://greasyfork.local/users/1
        // @version 1.0
        // @include *
        // ==/UserScript==
        var foo = "bar";
      JS
      script_version.rewritten_code = script_version.code
      script.apply_from_script_version(script_version)
      script.authors.build(user: User.find(1))
      script.code_updated_at = Time.current
      assert (script.valid? && script_version.valid?), (script.errors.full_messages + script_version.errors.full_messages + script_version.warnings).inspect
      return script
    end

    def with_sphinx
      ThinkingSphinx::Test.init
      ThinkingSphinx::Test.start index: true
      ThinkingSphinx::Configuration.instance.settings['real_time_callbacks'] = true
      yield
      ThinkingSphinx::Test.stop
      ThinkingSphinx::Test.clear
    end

    def assert_reindexes(&block)
      assert_changes -> { ThinkingSphinx::Deltas::TestDelta.index_count }, &block
    end
  end
end
