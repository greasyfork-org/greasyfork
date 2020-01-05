require 'test_helper'

class ScriptChecking::ExecutionCheckerTest < ActiveSupport::TestCase

  test 'ok' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_code('console.log').code
  end

  test 'error is ok' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_code('console log').code
  end

  test 'block set' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BLOCK, check_script_with_code('window.location.href = "bad.guy"').code
  end

  test 'block set on top-level object' do
    skip
    assert_equal ScriptChecking::Result::RESULT_CODE_BLOCK, check_script_with_code('location.href = "bad.guy"').code
  end

  test 'block function' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BLOCK, check_script_with_code('window.open("bad.guy")').code
  end

  def check_script_with_code(code)
    script_version = ScriptVersion.new(code: code)
    ScriptChecking::ExecutionChecker.check(script_version)
  end
end
