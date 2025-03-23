require 'application_system_test_case'

class UpdateTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test 'script update' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    code = <<~JS
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
    assert_reindexes do
      click_on 'Post new version'
      assert_on_script_tab('Info')
      assert_selector 'h2', text: 'A Test Update!'
    end
    assert_selector 'dd', text: '1.3'
  end

  test 'non-code update does not enqueue cache clear' do
    script = Script.find(6)
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    fill_in 'Changelog', with: 'A change'
    assert_reindexes do
      # assert_no_enqueued_jobs(only: ScriptUpdateCacheClearJob) do
      click_on 'Post new version'
      assert_on_script_tab('Info')
      # end
    end
  end

  test 'library update with meta block' do
    script = scripts(:library)
    original_name = script.name
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    code = <<~JS
      // ==UserScript==
      // @name A Test Update!
      // @description Unit test.
      // @version 1.2
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    fill_in 'Code', with: code
    click_on 'Post new version'
    assert_on_script_tab('Info')
    # @name is ignored in favour of the separate field on the form
    assert_selector 'h2', text: original_name
    assert_selector 'dd', text: '1.2'
  end

  test 'mark as adult manually' do
    script = Script.find(1)
    user = script.users.first
    login_as(user, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    code = <<~JS
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
    check 'This script contains adult content or is for a site that contains adult content.'
    click_on 'Post new version'
    assert_selector 'h2', text: 'A Test Update!'
    assert script.reload.sensitive?
    assert_equal user, script.marked_adult_by_user

    visit new_script_script_version_url(script_id: script.id)
    check 'This script does not contain adult content and is not for a site that contains adult content.'
    click_on 'Post new version'
    assert_on_script_tab('Info')
    assert_selector 'h2', text: 'A Test Update!'
    assert_not script.reload.sensitive?
    assert_nil script.not_adult_content_self_report_date
    assert_nil script.marked_adult_by_user
  end

  test 'mark as not adult when mod did it' do
    script = Script.find(1)
    script.update!(sensitive: true, marked_adult_by_user: User.moderators.first)
    login_as(script.users.first, scope: :user)
    visit new_script_script_version_url(script_id: script.id)
    code = <<~JS
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
    check 'This script does not contain adult content and is not for a site that contains adult content.'
    click_on 'Post new version'
    assert_on_script_tab('Info')
    assert_selector 'h2', text: 'A Test Update!'
    assert script.reload.sensitive?
    assert_not_nil script.not_adult_content_self_report_date
  end

  test 'sensitive site' do
    stub_es(Script) do
      script = Script.find(1)
      user = script.users.first
      login_as(user, scope: :user)
      visit new_script_script_version_url(script_id: script.id)
      code = <<~JS
        // ==UserScript==
        // @name A Test Update!
        // @description Unit test.
        // @version 1.3
        // @namespace http://greasyfork.local/users/1
        // @include http://pornonthecob.com
        // @license MIT
        // ==/UserScript==
        var foo = 1;
      JS
      fill_in 'Code', with: code
      click_on 'Post new version'

      assert_content 'Your script is for pornonthecob.com and so will be marked as adult content.'
      check 'Save anyway'
      click_on 'Post new version'

      assert_on_script_tab('Info')
      assert_selector 'h2', text: 'A Test Update!'
      assert script.reload.sensitive?
      assert_nil script.marked_adult_by_user

      visit new_script_script_version_url(script_id: script.id)
      assert_content 'Your script has been marked as having adult content due to being for pornonthecob.com.'
      click_on 'Post new version'

      assert_on_script_tab('Info')
      assert_selector 'h2', text: 'A Test Update!'
      assert script.reload.sensitive?
      assert_nil script.marked_adult_by_user
    end
  end
end
