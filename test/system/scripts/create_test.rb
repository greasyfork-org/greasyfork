require 'application_system_test_case'

class CreateTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test 'script creation' do
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
    # assert_no_enqueued_jobs(only: ScriptUpdateCacheClearJob) do
    click_on 'Post script'
    assert_selector 'h2', text: 'A Test!'
    # end
    assert_includes(Script.last.users, user)
  end

  test 'css script creation' do
    stub_es(Script) do
      user = User.first
      login_as(user, scope: :user)
      visit new_script_version_url(language: 'css')
      code = <<~CSS
        /* ==UserStyle==
        @name        Example UserCSS style
        @description This is an example
        @namespace   github.com/openstyles/stylus
        @version     1.0.0
        @license     unlicense
        ==/UserStyle== */

        @-moz-document domain("example.com") {
          a {
            color: red;
          }
        }
      CSS
      fill_in 'Code', with: code
      click_on 'Post script'
      assert_selector 'h2', text: 'Example UserCSS style'
      assert_includes(Script.last.users, user)
    end
  end

  test 'css script creation without meta' do
    user = User.first
    login_as(user, scope: :user)
    visit new_script_version_url(language: 'css')
    code = <<~CSS
      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    fill_in 'Code', with: code
    click_on 'Post script'
    assert_content 'is missing its metadata block'
  end

  test 'library creation with meta block' do
    user = User.first
    login_as(user, scope: :user)
    visit new_script_version_url
    code = <<~JS
      // ==UserScript==
      // @name My library
      // @description Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    fill_in 'Code', with: code
    choose 'Library - a script intended to be @require-d from other scripts and not installed directly.'
    click_on 'Post script'
    assert_selector 'h2', text: 'My library'
    assert_includes(Script.last.users, user)
  end

  test 'library creation without meta block' do
    user = User.first
    login_as(user, scope: :user)
    visit new_script_version_url
    code = <<~JS
      var foo = 1;
      var bar = 2;
    JS
    fill_in 'Code', with: code
    choose 'Library - a script intended to be @require-d from other scripts and not installed directly.'
    click_on 'Post script'
    fill_in 'Name', with: 'My library'
    fill_in 'Description', with: 'My library description'
    click_on 'Post script'
    assert_selector 'h2', text: 'My library'
    assert_includes(Script.last.users, user)
  end

  test 'blocked email domain' do
    user = User.first
    user.skip_reconfirmation!
    user.update(email: 'ich@derspamhaus.de')
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content 'You must confirm your account before you can post scripts.'
  end

  test 'suspicious email domain, not confirmed' do
    user = User.first
    user.skip_reconfirmation!
    user.update(email: 'salomon@fishy.hut', confirmed_at: nil)
    user.scripts.delete_all
    login_as(user, scope: :user)
    visit new_script_version_url
    click_link "I've written a script"
    assert_content 'You must confirm your account before you can post scripts.'
  end

  test 'confirmed, disposable email' do
    user = User.first
    user.update(email: 'test@example.com', confirmed_at: Time.current, disposable_email: true)
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content 'You may not post scripts if you use a disposable email address.'
  end

  test 'rate limited' do
    user = User.find(1)
    user.update(created_at: Time.current)
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content 'You have posted too many scripts recently. Please try again later.'
  end

  test 'multilang creation' do
    user = User.first
    login_as(user, scope: :user)
    visit new_script_version_url
    code = <<~JS
      // ==UserScript==
      // @name A Test!
      // @name:fr Un test!
      // @description Unit test.
      // @description:fr Test d'unit
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    fill_in 'Code', with: code
    fill_in 'Additional info', with: 'English additional info'

    click_on 'Add a localized additional info'
    select 'Français (fr)', from: 'script_version[additional_info][1][locale]', match: :first
    fill_in 'script_version[additional_info][1][attribute_value]', with: 'Additional info en francais'

    click_on 'Post script'

    assert_selector 'h2', text: 'A Test!'
    assert_includes(Script.last.users, user)
    assert_content 'Unit test.'
    assert_content 'English additional info'

    visit script_path(Script.last, locale: :fr)
    assert_selector 'h2', text: 'Un test!'
    assert_content "Test d'unit"
    assert_content 'Additional info en francais'
  end

  test 'script creation when secure requirements not met' do
    user = User.first
    user.update!(confirmed_at: nil)
    User.any_instance.expects(:require_secure_login_for_author?).returns(true).at_least_once
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content 'You must set up your account with a secure login method before you can post scripts.'
    assert_no_content '✓'
  end

  test 'script creation when only confirmed email secure requirement is met' do
    user = User.first
    User.any_instance.expects(:require_secure_login_for_author?).returns(true).at_least_once
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content '✓ Confirm your email address'
  end

  test 'script creation when only 2fa secure requirement is met' do
    user = User.first
    User.any_instance.expects(:require_secure_login_for_author?).returns(true).at_least_once
    user.update!(otp_required_for_login: true, confirmed_at: nil)
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content '✓ Enable two-factor authentication (2FA)'
  end

  test 'script creation when confirmed email and 2fa secure requirements are met' do
    user = User.first
    user.update!(confirmed_at: Time.zone.now, otp_required_for_login: true)
    User.any_instance.expects(:require_secure_login_for_author?).returns(true).at_least_once
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content 'Scripts must be properly described, cannot be obfuscated or minified, must respect copyright, and are limited in the external code used.'
  end

  test 'script creation when only external login requirement is met' do
    user = User.first
    User.any_instance.expects(:require_secure_login_for_author?).returns(true).at_least_once
    user.update!(confirmed_at: nil)
    user.identities.create!(provider: 'google', uid: '12345', syncing: false)
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content '✓ Add an external login'
  end

  test 'script creation when only external login and no password requirements are met' do
    user = User.first
    User.any_instance.expects(:require_secure_login_for_author?).returns(true).at_least_once
    user.update!(confirmed_at: nil, encrypted_password: nil)
    user.identities.create!(provider: 'google', uid: '12345', syncing: false)
    login_as(user, scope: :user)
    visit new_script_version_url
    assert_content 'Scripts must be properly described, cannot be obfuscated or minified, must respect copyright, and are limited in the external code used.'
  end
end
