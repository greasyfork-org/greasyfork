require 'test_helper'

class ScriptChecking::LinkCheckerTest < ActiveSupport::TestCase

  test 'not blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_url_in_code('https://example.com/this-is-ok').code
  end

  test 'directly blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_code('https://example.com/unique-test-value').code
  end

  test 'bit.ly not blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_url_in_code('https://bit.ly/2uaUwLP').code
  end

  test 'bit.ly blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_code('https://bit.ly/2SKn88z').code
  end

  test 'use in additional info not blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_url_in_additional_info('https://example.com/this-is-ok').code
  end

  test 'use in additional info blocked' do
    assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_additional_info('https://example.com/unique-test-value').code
  end

  def check_script_with_url_in_code(url)
    script_version = ScriptVersion.new(code: "location.href = '" + url + "'")
    ScriptChecking::LinkChecker.check(script_version)
  end

  def check_script_with_url_in_additional_info(url)
    script_version = ScriptVersion.new
    script_version.localized_attributes.build(attribute_key: 'additional_info', locale: locales(:english), attribute_value: url)
    ScriptChecking::LinkChecker.check(script_version)
  end
end
