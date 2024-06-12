require 'test_helper'

module ScriptChecking
  class CodeCheckerTest < ::ActiveSupport::TestCase
    test 'ok' do
      assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_code('console.log').code
    end

    test 'block' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BLOCK, check_script_with_code('this.is.a.warn = true').code
    end

    test 'ban' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('this.is.a.ban = true').code
    end

    test 'block and ban' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('this.is.a.warn = true; this.is.a.ban = true').code
    end

    test 'case differences with case sensitive matching' do
      assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_code('this.is.a.WARN = true').code
    end

    test 'case differences with case insensitive matching' do
      blocked_script_codes(:not_serious).update!(case_insensitive: true)
      assert_equal ScriptChecking::Result::RESULT_CODE_BLOCK, check_script_with_code('this.is.a.WARN = true').code
    end

    def check_script_with_code(code)
      script_version = ScriptVersion.new(code:)
      ScriptChecking::CodeChecker.check(script_version)
    end
  end
end
