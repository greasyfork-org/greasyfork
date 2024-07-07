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
end
