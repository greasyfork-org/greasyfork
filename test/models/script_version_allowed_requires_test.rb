require 'test_helper'

class ScriptVersionAllowedRequiresTest < ActiveSupport::TestCase
  test 'allowed require is allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include example.com
      // @require https://ajax.googleapis.com/whatever.js
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?
  end

  test 'invalid url in require is disallowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include example.com
      // @require https://ajax.googleapis.com/invalid\stuff
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
  end

  test 'require not on allowed list is not allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include example.com
      // @require https://ajax.jqueryorwhatever.com/whatever.js
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
  end
end
