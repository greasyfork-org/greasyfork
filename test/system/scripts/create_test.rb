require "application_system_test_case"

class CreateTest < ApplicationSystemTestCase
  test "script creation" do
    user = User.first
    login_as(user, scope: :user)
    visit new_script_version_url
    code = <<~EOF
      // ==UserScript==
      // @name A Test!
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      var foo = 1;
    EOF
    fill_in 'Code', with: code
    click_button 'Post script'
    assert_selector 'h2', text: 'A Test!'
    assert_includes(Script.last.users, user)
  end

  test 'blocked email domain' do
    user = User.first
    user.skip_reconfirmation!
    user.update(email: 'ich@derspamhaus.de')
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content "You must confirm your email before posting scripts."
  end

  test 'suspicious email domain, not confirmed' do
    user = User.first
    user.skip_reconfirmation!
    user.update(email: 'salomon@fishy.hut', confirmed_at: nil)
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content "You must confirm your email before posting scripts."
  end

  test "disallowed with originating script" do
    user = User.find(4)
    login_as(user, scope: :user)
    visit new_script_version_url
    code = <<~EOF
      // ==UserScript==
      // @name A Test!
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      this was copied from another script
    EOF
    fill_in 'Code', with: code
    click_button 'Post script'
    assert_selector 'li', text: 'This code appears to be an unauthorized copy'
  end
end
