require 'test_helper'
require 'js_parser'

class JsParserTest < ActiveSupport::TestCase
  test '::get_meta_block' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // ==/UserScript==
      var foo = "bar";
    JS
    meta_block = JsParser.get_meta_block(js)
    expected_meta = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // ==/UserScript==
    JS
    assert_equal expected_meta, meta_block
  end

  test '::get_meta_block no meta' do
    js = <<~JS
      var foo = "bar";
    JS
    meta_block = JsParser.get_meta_block(js)
    assert_nil meta_block
  end

  test '::parse_meta' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // ==/UserScript==
      var foo = "bar";
    JS
    meta = JsParser.parse_meta(js)
    assert_not_nil meta
    assert_equal 1, meta['name'].length
    assert_equal 'A Test!', meta['name'].first
    assert_equal 1, meta['description'].length
    assert_equal 'Unit test.', meta['description'].first
  end

  test '::parse_meta with no meta' do
    js = <<~JS
      var foo = "bar";
    JS
    meta = JsParser.parse_meta(js)
    assert_empty meta
  end

  test '::get_code_blocks' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      var foo = 'bar';
      foo.baz();
    JS
    assert_equal ['', "\nvar foo = 'bar';\nfoo.baz();\n"], JsParser.get_code_blocks(js)
  end

  test '::get_code_blocks meta not at top' do
    js = <<~JS
      var foo = 'bar';
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      foo.baz();
    JS
    assert_equal ["var foo = 'bar';\n", "\nfoo.baz();\n"], JsParser.get_code_blocks(js)
  end

  test '::get_code_blocks with no meta' do
    js = <<~JS
      var foo = 'bar';
      foo.baz();
    JS
    assert_equal ["var foo = 'bar';\nfoo.baz();\n", ''], JsParser.get_code_blocks(js)
  end

  test '::inject_meta replace' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      foo.baz();
    JS
    rewritten_js = JsParser.inject_meta(js, name: 'Something else')
    expected_js = "// ==UserScript==\n// @name		Something else\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nfoo.baz();\n"
    assert_equal expected_js, rewritten_js
  end

  test '::inject_meta remove' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      foo.baz();
    JS
    rewritten_js = JsParser.inject_meta(js, name: nil)
    expected_js = "// ==UserScript==\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nfoo.baz();\n"
    assert_equal expected_js, rewritten_js
  end

  test '::inject_meta remove not present' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      foo.baz();
    JS
    expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nfoo.baz();\n"
    assert_equal expected_js, JsParser.inject_meta(js, updateUrl: nil)
  end

  test '::inject_meta add' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      foo.baz();
    JS
    rewritten_js = JsParser.inject_meta(js, updateURL: 'http://example.com')
    expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// @updateURL http://example.com\n// ==/UserScript==\nfoo.baz();\n"
    assert_equal expected_js, rewritten_js
  end

  test '::inject_meta add if missing is missing' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      foo.baz();
    JS
    rewritten_js = JsParser.inject_meta(js, {}, { updateURL: 'http://example.com' })
    expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// @updateURL http://example.com\n// ==/UserScript==\nfoo.baz();\n"
    assert_equal expected_js, rewritten_js
  end

  test '::inject_meta add if missing isnt missing' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL http://example.com
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // ==/UserScript==
      foo.baz();
    JS
    rewritten_js = JsParser.inject_meta(js, {}, { updateURL: 'http://example.net' })
    expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @updateURL http://example.com\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nfoo.baz();\n"
    assert_equal expected_js, rewritten_js
  end
end
