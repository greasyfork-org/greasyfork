require 'test_helper'
require 'css_parser'

class CssParserTest < ActiveSupport::TestCase
  test '::get_meta_block' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    meta_block = CssParser.get_meta_block(css)
    expected_meta = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */
    CSS
    assert_equal expected_meta, meta_block
  end

  test '::get_meta_block no meta' do
    css = <<~CSS
      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    meta_block = CssParser.get_meta_block(css)
    assert_nil meta_block
  end

  test '::parse_meta' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @description The example didn't include this!
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    meta = CssParser.parse_meta(css)
    assert_not_nil meta
    assert_equal 1, meta['name'].length
    assert_equal 'Example UserCSS style', meta['name'].first
    assert_equal 1, meta['description'].length
    assert_equal "The example didn't include this!", meta['description'].first
  end

  test '::parse_meta with no meta' do
    css = <<~CSS
      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    meta = CssParser.parse_meta(css)
    assert_empty meta
  end

  test '::get_code_blocks' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal ['', "\n\n@-moz-document domain(\"example.com\") {\n  a {\n    color: red;\n  }\n}\n"], CssParser.get_code_blocks(css)
  end

  test '::get_code_blocks meta not at top' do
    css = <<~CSS
      @-moz-document domain("example1.com") {
        a {
          color: red;
        }
      }

      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example2.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal ["@-moz-document domain(\"example1.com\") {\n  a {\n    color: red;\n  }\n}\n\n", "\n\n@-moz-document domain(\"example2.com\") {\n  a {\n    color: red;\n  }\n}\n"], CssParser.get_code_blocks(css)
  end

  test '::get_code_blocks with no meta' do
    css = <<~CSS
      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal ["@-moz-document domain(\"example.com\") {\n  a {\n    color: red;\n  }\n}\n", ''], CssParser.get_code_blocks(css)
  end

  test '::inject_meta replace' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    rewritten_css = CssParser.inject_meta(css, name: 'Something else')
    expected_css = <<~CSS
      /* ==UserStyle==
      @name        Something else
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal expected_css, rewritten_css
  end

  test '::inject_meta remove' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    rewritten_css = CssParser.inject_meta(css, name: nil)
    expected_css = <<~CSS
      /* ==UserStyle==
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal expected_css, rewritten_css
  end

  test '::inject_meta remove not present' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    expected_css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal expected_css, CssParser.inject_meta(css, updateUrl: nil)
  end

  test '::inject_meta add' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    rewritten_css = CssParser.inject_meta(css, updateURL: 'http://example.com')
    expected_css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL http://example.com
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal expected_css, rewritten_css
  end

  test '::inject_meta add if missing is missing' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    rewritten_css = CssParser.inject_meta(css, {}, { updateURL: 'http://example.com' })
    expected_css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL http://example.com
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal expected_css, rewritten_css
  end

  test '::inject_meta add if missing isnt missing' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL   http://example.net
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    rewritten_css = CssParser.inject_meta(css, {}, { updateURL: 'http://example.net' })
    expected_css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL   http://example.net
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_equal expected_css, rewritten_css
  end
end
