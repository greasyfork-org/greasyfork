require 'test_helper'

class ScriptVersionAllowedResourcesTest < ActiveSupport::TestCase
  test 'https resource is allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @resource logo https://example.com/image.png
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?, script_version.errors.full_messages.to_sentence
  end

  test 'http resource is allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @resource logo http://example.com/image.png
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?, script_version.errors.full_messages.to_sentence
  end

  test 'data resource is allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @resource logo data:image/png,something
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?, script_version.errors.full_messages.to_sentence
  end

  test 'relative resource is not allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @resource logo /image.png
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?, script_version.errors.full_messages.to_sentence
  end

  test 'protocol-relative resource is allowed' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include https://example.com
      // @resource logo //example.com/image.png
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?, script_version.errors.full_messages.to_sentence
  end
end
