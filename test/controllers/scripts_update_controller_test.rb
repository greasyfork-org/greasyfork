require 'test_helper'

class ScriptsUpdateControllerTest < ActionDispatch::IntegrationTest
  test 'a normal script renders its code' do
    script = scripts(:one)
    get script.code_url
    assert_response :success
  end

  test 'a replaced script redirects properly on code URL' do
    original_script = scripts(:one)
    replacement_script = scripts(:two)
    original_script.update!(replaced_by_script_id: replacement_script.id, delete_type: :redirect)
    get original_script.code_url
    assert_redirected_to replacement_script.code_url
  end

  test 'a normal script renders its meta' do
    script = scripts(:one)
    get script.code_url(format_override: 'meta.js')
    assert_response :success
  end

  test 'a replaced script redirects properly on meta URL' do
    original_script = scripts(:one)
    replacement_script = scripts(:two)
    original_script.update!(replaced_by_script_id: replacement_script.id, delete_type: :redirect)
    get original_script.code_url(format_override: 'meta.js')
    assert_redirected_to replacement_script.code_url(format_override: 'meta.js')
  end
end
