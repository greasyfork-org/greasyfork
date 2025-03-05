ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'minitest/autorun'
require 'mocha/minitest'
require 'application_system_test_case'
require 'sidekiq/testing'

module ActiveSupport
  class TestCase
    ActiveRecord::Migration.check_all_pending!

    parallelize(workers: :number_of_processors)

    parallelize_setup do |i|
      ActiveStorage::Blob.service.root = "#{ActiveStorage::Blob.service.root}-#{i}"
    end

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
        // @license MIT
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

    def assert_reindexes(&)
      # TODO: Figure out how this might work. With SearchkickDisableMiddleware, we're turning off callbacks in the puma
      # process. Not sure how that would get turned back on.
      yield
    end

    def stub_es(klass)
      klass.stubs(:search).returns(klass.all.paginate(page: 1))
      yield if block_given?
    end
  end
end

Searchkick.disable_callbacks
