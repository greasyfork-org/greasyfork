require "application_system_test_case"

class UpdateTest < ApplicationSystemTestCase
  test "script update" do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    code = <<~EOF
      // ==UserScript==
      // @name A Test Update!
      // @description Unit test.
      // @version 1.2
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      var foo = 1;
    EOF
    fill_in 'Code', with: code
    click_button 'Post new version'
    assert_selector 'h2', text: 'A Test Update!'
    assert_selector 'dd', text: '1.2'
  end

  test "library update with meta block" do
    script = scripts(:library)
    original_name = script.name
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    code = <<~EOF
      // ==UserScript==
      // @name A Test Update!
      // @description Unit test.
      // @version 1.2
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      var foo = 1;
    EOF
    fill_in 'Code', with: code
    click_button 'Post new version'
    # @name is ignored in favour of the separate field on the form
    assert_selector 'h2', text: original_name
    assert_selector 'dd', text: '1.2'
  end
end
