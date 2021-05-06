require 'test_helper'
require 'script_importer/url_importer'

class UrlImporterTest < ActiveSupport::TestCase
  test 'generate script' do
    result, script, message = ScriptImporter::UrlImporter.generate_script('https://github.com/scintill/userscripts/raw/master/routey-on-home.user.js', nil, User.find(1))
    assert_equal :success, result, message
    assert_not_nil script
    assert_equal 'Route Y links on the BYU Home Page', script.name
    assert_equal 'https://github.com/scintill/userscripts/raw/master/routey-on-home.user.js', script.sync_identifier
  end

  test 'triggering script checking' do
    ScriptImporter::UrlImporter.expects(:download).returns(<<~JS)
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      this.is.a.warn = true
    JS
    result, _script, message = ScriptImporter::UrlImporter.generate_script('https://github.com/scintill/userscripts/raw/master/routey-on-home.user.js', nil, User.find(1))
    assert_equal :failure, result
    assert_equal 'Warning', message
  end
end
