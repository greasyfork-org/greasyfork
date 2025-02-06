require 'application_system_test_case'

class BlockTest < ApplicationSystemTestCase
  test 'banned via disallowed url' do
    user = User.find(4)
    user.update!(created_at: 1.day.ago)
    login_as(user, scope: :user)
    visit new_script_version_url
    click_on "I've written a script and want to share it with others."
    code = <<~JS
      // ==UserScript==
      // @name A Test!
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com/*
      // @license MIT
      // ==/UserScript==
      location.href = "https://example.com/unique-test-value"
    JS
    fill_in 'Code', with: code
    assert_changes -> { user.reload.banned? }, from: false, to: true do
      click_on 'Post script'
      assert_content 'Your account has been banned.'
    end
  end

  test 'blocked with originating script' do
    login_as(User.find(4))
    visit new_script_version_url
    click_on "I've written a script and want to share it with others."
    code = <<~JS
      // ==UserScript==
      // @name A Test!
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      some.unique[value]
    JS
    fill_in 'Code', with: code
    click_on 'Post script'
    assert_content 'This appears to be an unauthorized copy'
  end

  test 'not blocked when same author' do
    origin = scripts(:copy_origin)
    login_as(origin.users.first, scope: :user)
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
      some.unique[value]
    JS
    fill_in 'Code', with: code
    assert_difference -> { ScriptVersion.count } => 1 do
      click_on 'Post script'
    end
  end

  test 'updating originating script' do
    origin = scripts(:copy_origin)
    login_as(origin.users.first, scope: :user)
    visit new_script_script_version_url(script_id: origin.id)
    code = <<~JS
      // ==UserScript==
      // @name A Test!
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      some.unique[value]
    JS
    fill_in 'Code', with: code
    assert_difference -> { ScriptVersion.count } => 1 do
      click_on 'Post new version'
    end
  end

  test 'banned via disallowed text' do
    user = User.find(4)
    login_as(user, scope: :user)
    visit new_script_version_url
    click_on "I've written a script and want to share it with others."
    code = <<~JS
      // ==UserScript==
      // @name badguytext
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      location.href = "something"
    JS
    fill_in 'Code', with: code
    assert_difference -> { Script.count } => 1 do
      click_on 'Post script'
      assert_content 'This script is unavailable to other users until it is reviewed by a moderator.'
    end
    assert_equal 'required', Script.last.review_state
  end

  test 'review required for code' do
    stub_es(Script)
    user = User.find(4)
    user.update!(created_at: 1.day.ago)
    login_as(user, scope: :user)
    visit new_script_version_url
    click_on "I've written a script and want to share it with others."
    code = <<~JS
      // ==UserScript==
      // @name A Test!
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com/*
      // @license MIT
      // ==/UserScript==
      this.is.a.review = true
    JS
    fill_in 'Code', with: code
    assert_difference -> { Script.count } => 1 do
      click_on 'Post script'
      assert_content 'This script is unavailable to other users until it is reviewed by a moderator.'
    end
    assert_equal 'required', Script.last.review_state
  end
end
