require 'test_helper'

module ScriptChecking
  class LinkCheckerTest < ::ActiveSupport::TestCase
    test 'not blocked' do
      assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_url_in_code('https://example.com/this-is-ok').code
    end

    test 'directly blocked' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_code('https://example.com/unique-test-value').code
    end

    test 'directly blocked with params' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_code('https://example.com/unique-test-value?query').code
    end

    test 'directly blocked with hash' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_code('https://example.com/unique-test-value#hash').code
    end

    test 'bit.ly not blocked' do
      assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_url_in_code('https://bit.ly/39soMRq').code
    end

    test 'bit.ly blocked' do
      blocked_script_urls(:first).update(url: 'http://example.com/')
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_code('https://bit.ly/39soMRq').code
    end

    test 'bit.ly blocked with prefix' do
      blocked_script_urls(:first).update(url: 'http://exa', prefix: true)
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_code('https://bit.ly/39soMRq').code
    end

    test 'bit.ly not blocked with prefix' do
      blocked_script_urls(:first).update(url: 'http://hexa', prefix: true)
      assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_url_in_code('https://bit.ly/39soMRq').code
    end

    test 'redirect via meta refresh' do
      blocked_script_urls(:first).update(url: 'http://yemao.vip/wenku')
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_code('https://www.baidu.com/link?url=8nlvrkK6WmqkZ0GEDVQy3Cy8GdPwHhuAzfQZu8lXsJy&wd=&eqid=a682cd1900025b0f000000055f8c009d').code
    end

    test 'use in additional info not blocked' do
      assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_url_in_additional_info('https://example.com/this-is-ok').code
    end

    test 'use in additional info blocked' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_url_in_additional_info('https://example.com/unique-test-value').code
    end

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

    test 'block function with concat' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('window.open("https://example.com/" + "unique-test-value")').code
    end

    test 'block function with concat and query params' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('window.open("https://example.com/" + "unique-test-value" + "?foo=bar")').code
    end

    test 'block function with concat and hash' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_code('window.open("https://example.com/" + "unique-test-value" + "#hash")').code
    end

    test 'safe browsing' do
      skip unless Rails.application.secrets.google_safe_browsing_api_key
      assert_equal ScriptChecking::Result::RESULT_CODE_BLOCK, check_script_with_code('location.href = "https://testsafebrowsing.appspot.com/s/phishing.html"').code
    end

    def check_script_with_code(code)
      script_version = ScriptVersion.new(code: code)
      ScriptChecking::LinkChecker.check(script_version)
    end

    def check_script_with_url_in_code(url)
      script_version = ScriptVersion.new(code: "location.href = '#{url}'")
      ScriptChecking::LinkChecker.check(script_version)
    end

    def check_script_with_url_in_additional_info(url)
      script_version = ScriptVersion.new
      script_version.localized_attributes.build(attribute_key: 'additional_info', locale: locales(:english), attribute_value: url)
      ScriptChecking::LinkChecker.check(script_version)
    end
  end
end
