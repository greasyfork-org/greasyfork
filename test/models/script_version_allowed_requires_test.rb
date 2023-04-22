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
      // @include https://example.com
      // @require https://ajax.googleapis.com/whatever.js
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?, script_version.errors.full_messages.to_sentence
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
      // @include https://example.com
      // @require https://ajax.googleapis.com/invalid^stuff
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
    assert_includes script_version.errors.full_messages, 'Code uses a malformed external script reference: @require https://ajax.googleapis.com/invalid^stuff'
  end

  test 'relative url in require is disallowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @require jquery.min.js
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
    assert_includes script_version.errors.full_messages, 'Code uses an unapproved external script: @require jquery.min.js'
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
      // @include https://example.com
      // @require https://ajax.jqueryorwhatever.com/whatever.js
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
    assert_includes script_version.errors.full_messages, 'Code uses an unapproved external script: @require https://ajax.jqueryorwhatever.com/whatever.js'
  end

  test 'require not on allowed list is allowed if it has a subresource integrity hash' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @require https://ajax.jqueryorwhatever.com/whatever.js#sha256=abc123
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?, script_version.errors.full_messages.to_sentence
  end

  test "require not on allowed list is allowed if it's for the single matched site" do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://ajax.jqueryorwhatever.com
      // @require https://ajax.jqueryorwhatever.com/whatever.js
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?
  end

  test 'require not on allowed list is allowed if it matches the domain of all matched sites' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://ajax.jqueryorwhatever.com/first-page
      // @include https://ajax.jqueryorwhatever.com/second-page
      // @require https://ajax.jqueryorwhatever.com/whatever.js
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?
  end

  test 'require not on allowed list is not allowed if it matches one site but not another' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://ajax.jqueryorwhatever.com
      // @include https://example.com
      // @require https://ajax.jqueryorwhatever.com/whatever.js
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
    assert_includes script_version.errors.full_messages, 'Code uses an unapproved external script: @require https://ajax.jqueryorwhatever.com/whatever.js'
  end

  test 'data URI require is allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @require data:text/javascript,window.vue = {}
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?, script_version.errors.full_messages.to_sentence
  end
end
