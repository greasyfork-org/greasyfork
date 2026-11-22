require 'test_helper'

class ScriptVersionParamsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'rejecting missing or malformed script parameters on creation' do
    sign_in users(:one)
    get new_script_version_path(locale: :en)
    token = response.parsed_body.at_css('form input[name="authenticity_token"]')['value']

    [nil, 'invalid', { adult_content_self_report: '0' }, { script_type: ['1'] }].each do |script_params|
      assert_no_difference -> { Script.count } do
        assert_raises(ActionController::ParameterMissing) do
          post script_versions_path(locale: :en), params: {
            authenticity_token: token,
            script: script_params,
            script_version: { code: script_codes(:one).code },
          }
        end
      end
    end
  end

  test 'rejecting missing script parameters on update without changing the script' do
    script = scripts(:one)
    sign_in script.users.first
    get new_script_script_version_path(script_id: script.id, locale: :en)
    token = response.parsed_body.at_css('form input[name="authenticity_token"]')['value']
    original_type = script.script_type

    assert_no_difference -> { script.script_versions.count } do
      assert_raises(ActionController::ParameterMissing) do
        post script_script_versions_path(script_id: script, locale: :en), params: {
          authenticity_token: token,
          script_version: { code: script.newest_saved_script_version.code },
        }
      end
    end
    assert_equal original_type, script.reload.script_type
  end

  test 'previewing an update retains the selected script type without saving it' do
    script = scripts(:one)
    original_type = script.script_type
    sign_in script.users.first
    get new_script_script_version_path(script_id: script.id, locale: :en)
    token = response.parsed_body.at_css('form input[name="authenticity_token"]')['value']

    assert_no_difference -> { script.script_versions.count } do
      post script_script_versions_path(script_id: script, locale: :en), params: {
        authenticity_token: token,
        preview: '1',
        script: { script_type: Script.script_types[:unlisted].to_s },
        script_version: { code: script.newest_saved_script_version.code },
      }
    end

    assert_response :success
    assert_select 'input[name="script[script_type]"][value="2"][checked]'
    assert_equal original_type, script.reload.script_type
  end
end
