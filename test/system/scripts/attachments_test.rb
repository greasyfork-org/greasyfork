require 'application_system_test_case'

class AttachmentsTest < ApplicationSystemTestCase
  test 'adding and removing attachments' do
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
    attach_file 'Add:', [Rails.root.join('public/images/blacklogo16.png'), Rails.root.join('public/images/blacklogo32.png')]
    click_button 'Post script'
    assert_selector 'h2', text: 'A Test!'
    assert_includes(Script.last.users, user)
    assert_selector '.user-screenshots img', count: 2

    click_link 'Update'
    within '.remove-attachment-selecter', match: :first do
      check 'Remove'
    end
    attach_file 'Add:', [Rails.root.join('public/images/blacklogo128.png')]
    click_button 'Post new version'

    assert_selector ".user-screenshots img[src*='blacklogo32.png']"
    assert_selector ".user-screenshots img[src*='blacklogo128.png']"
  end
end
