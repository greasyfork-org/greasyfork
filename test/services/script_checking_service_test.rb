require 'test_helper'

class ScriptCheckingServiceTest < ActiveSupport::TestCase
  test 'not blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script('https://example.com/this-is-ok').last
  end

  test 'directly blocked' do
    result = check_script('https://example.com/unique-test-value')
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, result.last
    assert_equal 'Test value', result.first.first.public_reason
  end

  def check_script(url)
    script_version = ScriptVersion.new(code: "location.href = '#{url}'", script: Script.new)
    ScriptCheckingService.check(script_version)
  end
end
