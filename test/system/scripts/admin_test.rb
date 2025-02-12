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

  test 'setting synced, localized additional infos' do
    ScriptImporter::TestImporter.expects(:download).with('https://example.com/code').returns(<<~JS).at_least_once
      // ==UserScript==
      // @name		A Test!
      // @name:fr French name
      // @name:es Spanish name
      // @name:pt Portuguese name
      // @description		Unit test.
      // @description:fr French description
      // @description:es Spanish description
      // @description:pt Portuguese description
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      let foo = 'bar'
    JS
    ScriptImporter::TestImporter.expects(:download).with('https://example.com/en').returns('English add').at_least_once
    ScriptImporter::TestImporter.expects(:download).with('https://example.com/fr').returns('French add').at_least_once
    ScriptImporter::TestImporter.expects(:download).with('https://example.com/es').returns('Spanish add').at_least_once
    ScriptImporter::TestImporter.expects(:download).with('https://example.com/pt').returns('Portuguese add').at_least_once

    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)

    fill_in 'script[sync_identifier]', with: 'https://example.com/code'
    choose 'Manual - it will be checked for updates only when you trigger it'

    fill_in 'Default additional info', with: 'https://example.com/en'
    click_on 'Add a localized, synced additional info'
    fill_in 'For locale (matches @name:XX)', with: 'https://example.com/fr'
    select 'Français (fr)', from: 'additional_info_sync[1][locale]', match: :first
    click_on 'Add a localized, synced additional info'
    fill_in 'additional_info_sync[2][sync_identifier]', with: 'https://example.com/es'
    select 'Español (es)', from: 'additional_info_sync[2][locale]', match: :first
    click_on 'Update and sync now'
    assert_content 'Script successfully synced.'

    script.reload

    assert_equal 'English add', script.additional_info(:en)
    assert_equal 'French add', script.additional_info(:fr)
    assert_equal 'Spanish add', script.additional_info(:es)

    visit admin_script_url(script, locale: :en)

    click_on 'Add a localized, synced additional info'
    fill_in 'additional_info_sync[3][sync_identifier]', with: 'https://example.com/pt'
    select 'Português (pt)', from: 'additional_info_sync[3][locale]', match: :first
    click_on 'Update and sync now'
    assert_content 'Script successfully synced.'

    script.reload

    assert_equal 'English add', script.additional_info(:en)
    assert_equal 'French add', script.additional_info(:fr)
    assert_equal 'Spanish add', script.additional_info(:es)
    assert_equal 'Portuguese add', script.additional_info(:pt)
  end
end
