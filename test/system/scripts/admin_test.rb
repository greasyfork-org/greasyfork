require 'application_system_test_case'
require 'script_importer/test_importer'

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

  test 'setting a sync URL using the wrong kind of GitHub URL' do
    ScriptImporter::TestImporter.expects(:download).returns(<<~JS)
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      let foo = 'bar'
    JS

    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'script[sync_identifier]', with: 'https://github.com/adamlui/autoclear-chatgpt-history/blob/main/greasemonkey/autoclear-chatgpt-history.user.js'
    choose 'Manual - it will be checked for updates only when you trigger it'
    click_on 'Update and sync now'
    assert_content 'Script successfully synced.'
    assert_equal 'https://github.com/adamlui/autoclear-chatgpt-history/raw/main/greasemonkey/autoclear-chatgpt-history.user.js', script.reload.sync_identifier
  end
end
