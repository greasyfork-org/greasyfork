require 'test_helper'

class ScriptChecking::LinkCheckerTest < ActiveSupport::TestCase

  test 'not blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script('https://example.com/this-is-ok').code
  end

  test 'directly blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script('https://example.com/unique-test-value').code
  end

  test 'bit.ly not blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script('https://bit.ly/2uaUwLP').code
  end

  test 'bit.ly blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script('https://bit.ly/2SKn88z').code
  end

  def check_script(url)
    script_version = ScriptVersion.new(code: "location.href = '" + url + "'")
    ScriptChecking::LinkChecker.check(script_version)
  end
end