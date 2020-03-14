require 'application_system_test_case'

class ScriptAdminTest < ApplicationSystemTestCase
  test 'setting a promoted script' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'URL of script to promote', with: 'https://greasyfork.org/scripts/2-something'
    click_button 'Set promoted script'
    assert_content 'Script updated'
    assert_equal 2, script.reload.promoted_script_id
    fill_in 'URL of script to promote', with: ''
    click_button 'Set promoted script'
    assert_content 'Script updated'
    assert_nil script.reload.promoted_script_id
  end
end
