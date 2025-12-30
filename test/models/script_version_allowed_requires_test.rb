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

  test 'invalid url with subresource integrity in require is disallowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @require https://ajax.googleapis.com/invalid^stuff#sha256=d776ab56bb50565a43df1932d2c28ce22574a00f33c9663bd5fd687fc64d9607
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
    assert_includes script_version.errors.full_messages, 'Code uses a malformed external script reference: @require https://ajax.googleapis.com/invalid^stuff#sha256=d776ab56bb50565a43df1932d2c28ce22574a00f33c9663bd5fd687fc64d9607'
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

  test 'base 64 data URI require is not allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @require data:text/javascript;base64,d2luZG93LnZ1ZSA9IHt9
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
    assert_includes script_version.errors.full_messages, 'Code uses a base-64 encoded @require'
  end
end
