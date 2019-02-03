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
end
