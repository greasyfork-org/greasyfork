require 'application_system_test_case'

class AdditionalInfoTest < ApplicationSystemTestCase
  test 'mentions' do
    user = User.first
    login_as(user, scope: :user)
    mentioned_user1 = users(:geoff)
    mentioned_user2 = users(:consumer)

    visit new_script_version_url
    code = <<~JS
      // ==UserScript==
      // @name A Test!
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      var foo = 1;
    JS
    fill_in 'Code', with: code
    fill_in 'Additional info', with: 'Hey @Geoffrey this is for you!'
    click_button 'Post script'
    assert_selector 'h2', text: 'A Test!'
    script = Script.last

    assert_link '@Geoffrey', href: user_path(mentioned_user1, locale: :en)

    visit new_script_script_version_url(script_id: script.id)
    fill_in 'Additional info', with: 'Hey @"Gordon J. Canada" this is for you!'
    click_button 'Post new version'
    assert_selector 'h2', text: 'A Test!'
    assert_link '@"Gordon J. Canada"', href: user_path(mentioned_user2, locale: :en)

    visit script_path(script, version: script.script_versions.first.id, locale: :en)
    assert_link '@Geoffrey', href: user_path(mentioned_user1, locale: :en)

    visit script_path(script, version: script.script_versions.last.id, locale: :en)
    assert_link '@"Gordon J. Canada"', href: user_path(mentioned_user2, locale: :en)
  end

  test 'changing just additional info reindexes' do
    script = Script.find(11)
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    fill_in 'Additional info', with: 'New, different content'
    assert_reindexes do
      assert_difference -> { ScriptVersion.count } => 1 do
        click_button 'Post new version'
        assert_content 'New, different content'
      end
    end
  end
end
