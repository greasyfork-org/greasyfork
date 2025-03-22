require 'application_system_test_case'

class ScriptWarningsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test 'does not start with meta' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    code = <<~JS
      /* LICENSE */
      // ==UserScript==
      // @name A Test Update!
      // @description Unit test.
      // @version 1.3
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    fill_in 'Code', with: code
    click_on 'Post new version'
    assert_content 'Your code does not begin with'
    check 'Save anyway'
    assert_reindexes do
      click_on 'Post new version'
      assert_on_script_tab('Info')
      assert_selector 'h2', text: 'A Test Update!'
    end
    assert_selector 'dd', text: '1.3'
  end
end
