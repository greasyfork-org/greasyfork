require "application_system_test_case"

class CreateTest < ApplicationSystemTestCase
  test "script creation" do
    login_as(User.first, scope: :user)
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
    assert_equal User.first, Script.last.user
  end

  test 'blocked email domain' do
    user = User.first
    user.update(email: 'ich@derspamhaus.de')
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content "You must confirm your email before posting scripts."
  end

  test 'suspicious email domain, not confirmed' do
    user = User.first
    user.update(email: 'salomon@fishy.hut', confirmed_at: nil)
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content "You must confirm your email before posting scripts."
  end

  test 'suspicious email domain, confirmed' do
    user = User.first
    user.update(email: 'salomon@fishy.hut', confirmed_at: Date.today)
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content 'Scripts must be properly described'
  end
end
