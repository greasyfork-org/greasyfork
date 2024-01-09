require 'application_system_test_case'

class ScriptAdminTest < ApplicationSystemTestCase
  test 'setting a promoted script' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'URL of script to promote', with: 'https://greasyfork.org/scripts/2-something'
    click_on 'Set promoted script'
    assert_content 'Script updated'
    assert_equal 2, script.reload.promoted_script_id
    fill_in 'URL of script to promote', with: ''
    click_on 'Set promoted script'
    assert_content 'Script updated'
    assert_nil script.reload.promoted_script_id
  end

  test 'setting a sensitive promoted script' do
    script = Script.find(1)
    other_script = Script.find(2)
    other_script.update!(sensitive: true)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'URL of script to promote', with: 'https://greasyfork.org/scripts/2-something'
    click_on 'Set promoted script'
    assert_content "Promoted script can't be used with this script"
  end

  test 'setting a sensitive promoted script when this script is also sensitive' do
    script = Script.find(1)
    script.update!(sensitive: true)
    other_script = Script.find(2)
    other_script.update!(sensitive: true)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'URL of script to promote', with: 'https://greasyfork.org/scripts/2-something'
    click_on 'Set promoted script'
    assert_content 'Script updated'
    assert_equal 2, script.reload.promoted_script_id
  end

  test 'setting a sensitive promoted script when this script is also sensitive using a sleazy url' do
    script = Script.find(1)
    script.update!(sensitive: true)
    other_script = Script.find(2)
    other_script.update!(sensitive: true)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'URL of script to promote', with: 'https://sleazyfork.org/scripts/2-something'
    click_on 'Set promoted script'
    assert_content 'Script updated'
    assert_equal 2, script.reload.promoted_script_id
  end
end
