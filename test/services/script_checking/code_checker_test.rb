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

    def check_script_with_code(code)
      script_version = ScriptVersion.new(code: code)
      ScriptChecking::CodeChecker.check(script_version)
    end
  end
end
