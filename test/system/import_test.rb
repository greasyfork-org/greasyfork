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
    assert_content 'Does not appear to be a user script.'
  end
end
