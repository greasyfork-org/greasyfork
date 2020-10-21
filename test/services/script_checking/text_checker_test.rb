require 'test_helper'

module ScriptChecking
  class TextCheckerTest < ::ActiveSupport::TestCase
    test 'ok' do
      assert_equal ScriptChecking::Result::RESULT_CODE_OK, check_script_with_additional_info('goodguytext').code
    end

    test 'review' do
      assert_equal ScriptChecking::Result::RESULT_CODE_REVIEW, check_script_with_additional_info('badguytext').code
    end

    test 'ban' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_additional_info('horribleguytext').code
    end

    test 'review + ban = ban' do
      assert_equal ScriptChecking::Result::RESULT_CODE_BAN, check_script_with_additional_info('badguytext horribleguytext').code
    end

    def check_script_with_additional_info(text)
      script_version = ScriptVersion.new
      script_version.localized_attributes.build(attribute_key: 'additional_info', locale: locales(:english), attribute_value: text)
      ScriptChecking::TextChecker.check(script_version)
    end
  end
end
