require 'application_system_test_case'
require 'script_importer/test_importer'

class ImportTest < ApplicationSystemTestCase
  test 'importing a script successfully' do
    ScriptImporter::TestImporter.expects(:download).returns(<<~JS)
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      let foo = 'bar'
    JS

    login_as(User.first, scope: :user)
    visit import_start_url
    fill_in 'Provide URLs to import from, separated by newlines.', with: 'https://example.com'
    click_button 'Import'
    assert_content 'The following scripts were successfully imported:'
  end

  test 'importing CSS' do
    ScriptImporter::TestImporter.expects(:download).returns(<<~CSS)
      /* ==UserStyle==
      @name A Test Update!
      @description Unit test.
      @version 1.2
      @namespace http://greasyfork.local/users/1
      @include *
      @antifeature ads this has ads
      @license MIT
      ==/UserStyle== */
      @-moz-document domain(example.com) {
        a { color: blue }
      }
    CSS

    login_as(User.first, scope: :user)
    visit import_start_url
    fill_in 'Provide URLs to import from, separated by newlines.', with: 'https://example.com'
    choose 'CSS'
    click_button 'Import'
    assert_content 'The following scripts were successfully imported:'
  end

  test 'importing CSS but not with .css and not specifying' do
    ScriptImporter::TestImporter.expects(:download).returns(<<~CSS)
      /* ==UserStyle==
      @name A Test Update!
      @description Unit test.
      @version 1.2
      @namespace http://greasyfork.local/users/1
      @include *
      @antifeature ads this has ads
      @license MIT
      ==/UserStyle== */
      @-moz-document domain(example.com) {
        a { color: blue }
      }
    CSS

    login_as(User.first, scope: :user)
    visit import_start_url
    fill_in 'Provide URLs to import from, separated by newlines.', with: 'https://example.com'
    click_button 'Import'
    assert_content 'The following scripts could not be imported.'
  end

  test 'importing a library' do
    ScriptImporter::TestImporter.expects(:download).returns(<<~JS).at_least(2)
      let foo = 'bar has enough characters to reach the minimum'
    JS

    login_as(User.first, scope: :user)
    visit import_start_url
    fill_in 'Provide URLs to import from, separated by newlines.', with: 'https://example.com'
    click_button 'Import'
    assert_content 'The following scripts could not be imported. If they are JS libraries not meant to be directly installed, you can click the link to add them as such.'
    click_button 'Add as library'
    assert_field('script_version[code]', with: "let foo = 'bar has enough characters to reach the minimum'\n")
    fill_in 'Name', with: 'Test library'
    fill_in 'Description', with: 'Test library descrpition'
    click_on 'Post script'
    assert_selector 'h2', text: 'Test library'

    script = Script.last
    assert_equal 'https://example.com', script.sync_identifier
    assert_equal 'automatic', script.sync_type
    assert_not_nil script.last_attempted_sync_date
    assert_not_nil script.last_successful_sync_date
  end
end
