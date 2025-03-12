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
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    fill_in 'Code', with: code
    fill_in 'Additional info', with: 'Hey @Geoffrey this is for you!'
    click_on 'Post script'
    assert_on_script_tab('Info')
    script = Script.last

    assert_link '@Geoffrey', href: user_path(mentioned_user1, locale: :en)

    visit new_script_script_version_url(script_id: script.id)
    fill_in 'Additional info', with: 'Hey @"Gordon J. Canada" this is for you!'
    click_on 'Post new version'
    assert_on_script_tab('Info')
    assert_link '@Gordon J. Canada', href: user_path(mentioned_user2, locale: :en)

    visit script_path(script, version: script.script_versions.first.id, locale: :en)
    assert_link '@Geoffrey', href: user_path(mentioned_user1, locale: :en)

    visit script_path(script, version: script.script_versions.last.id, locale: :en)
    assert_link '@Gordon J. Canada', href: user_path(mentioned_user2, locale: :en)
  end

  test 'mention retention and deletion' do
    user = User.first
    login_as(user, scope: :user)

    visit new_script_version_url
    code = <<~JS
      // ==UserScript==
      // @name A Test!
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    fill_in 'Code', with: code
    fill_in 'Additional info', with: 'Hey @Geoffrey this is for you!'
    click_on 'Post script'
    assert_on_script_tab('Info')
    script = Script.last
    script_version = script.script_versions.last
    [script, script_version].each do |o|
      assert_equal 1, o.localized_attribute_for('additional_info').mentions.count
      assert_equal '@Geoffrey', o.localized_attribute_for('additional_info').mentions.first.text
    end

    # No update
    visit new_script_script_version_url(script_id: script.id)
    click_on 'Post new version'
    assert_on_script_tab('Info')
    script.reload
    script_version = script.script_versions.last
    [script, script_version].each do |o|
      assert_equal 1, o.localized_attribute_for('additional_info').mentions.count
      assert_equal '@Geoffrey', o.localized_attribute_for('additional_info').mentions.first.text
    end

    # Update the additional info, but retain the mention
    visit new_script_script_version_url(script_id: script.id)
    fill_in 'Additional info', with: 'Hey @Geoffrey this is for you!!!!!!'
    click_on 'Post new version'
    assert_on_script_tab('Info')
    script.reload
    script_version = script.script_versions.last
    [script, script_version].each do |o|
      assert_equal 1, o.localized_attribute_for('additional_info').mentions.count
      assert_equal '@Geoffrey', o.localized_attribute_for('additional_info').mentions.first.text
    end

    # Update the additional info, mentioning a different user
    visit new_script_script_version_url(script_id: script.id)
    fill_in 'Additional info', with: 'Hey @"Gordon J. Canada" this is for you!'
    click_on 'Post new version'
    assert_on_script_tab('Info')
    script.reload
    script_version = script.script_versions.last
    [script, script_version].each do |o|
      assert_equal 1, o.localized_attribute_for('additional_info').mentions.count
      assert_equal '@"Gordon J. Canada"', o.localized_attribute_for('additional_info').mentions.first.text
    end

    # No longer mention anyone
    visit new_script_script_version_url(script_id: script.id)
    fill_in 'Additional info', with: 'This is for no one'
    click_on 'Post new version'
    assert_on_script_tab('Info')
    script.reload
    script_version = script.script_versions.last
    [script, script_version].each do |o|
      assert_empty o.localized_attribute_for('additional_info').mentions
    end
  end

  test 'changing just additional info reindexes' do
    script = Script.find(11)
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    fill_in 'Additional info', with: 'New, different content'
    assert_reindexes do
      assert_difference -> { ScriptVersion.count } => 1 do
        click_on 'Post new version'
        assert_content 'New, different content'
      end
    end
  end

  test 'relative links in imported markdown are relative to sync source' do
    script = Script.find(1)
    ai = script.localized_additional_infos.first
    ai.update!(attribute_value: '[Relative link](/mylink)', value_markup: 'markdown')
    visit script_url(script, locale: :en)
    assert_selector 'a[href="/mylink"]'

    ai.update!(sync_identifier: 'https://example.com')
    visit script_url(script, locale: :en)
    assert_selector 'a[href="https://example.com/mylink"]'
  end

  test 'anchor-only links in imported markdown are left alone' do
    script = Script.find(1)
    ai = script.localized_additional_infos.first
    ai.update!(attribute_value: '[Anchor link](#top)', value_markup: 'markdown')
    visit script_url(script, locale: :en)
    assert_selector 'a[href="#top"]'

    ai.update!(sync_identifier: 'https://example.com')
    visit script_url(script, locale: :en)
    assert_selector 'a[href="#top"]'
  end
end
