require 'test_helper'

class ScriptChecking::ExecutionCheckerTest < ActiveSupport::TestCase

  test 'ok' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_code('console.log').code
  end

  test 'error is ok' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_code('console log').code
  end

  test 'block set' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('window.location.href = "https://example.com/unique-test-value"').code
  end

  test 'block set for OK URL' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_code('window.location.href = "https://example.com/innocent-value"').code
  end

  test 'block set on top-level object' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('location.href = "https://example.com/unique-test-value"').code
  end

  test 'block set of top-level object' do
    skip
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('location = "https://example.com/unique-test-value"').code
  end

  test 'block function' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('window.open("https://example.com/unique-test-value")').code
  end

  test 'block within setTimeout' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('setTimeout(function() { window.open("https://example.com/unique-test-value") }, 1000)').code
  end

  test 'block within addEventListener' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('addEventListener("load", function() { window.open("https://example.com/unique-test-value") }, 1000)').code
  end

  test 'block within addEventListener on another object' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('document.getElementById("foo").addEventListener("click", function() { window.open("https://example.com/unique-test-value") }, 1000)').code
  end

  def check_script_with_code(code)
    script_version = ScriptVersion.new(code: code)
    ScriptChecking::ExecutionChecker.check(script_version)
  end
end
