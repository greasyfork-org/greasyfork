require 'test_helper'

class CssParserAppliesToTest < ActiveSupport::TestCase
  def get_applies_tos(code)
    CssParser.calculate_applies_to_names(code)
  end

  test 'applies to everything' do
    css = <<~CSS
      a { color: red; }
    CSS
    assert_empty get_applies_tos(css)
  end

  test 'applies to single domain' do
    css = <<~CSS
      @-moz-document domain(example.com) {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_tos(css)
  end

  test 'applies to single url' do
    css = <<~CSS
      @-moz-document url('http://www.example.com') {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_tos(css)
  end

  test 'applies to single url-prefix' do
    css = <<~CSS
      @-moz-document url-prefix("http://www.example.com/") {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_tos(css)
  end

  test 'applies to single url-prefix with domain wildcard' do
    css = <<~CSS
      @-moz-document url-prefix("http://example") {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: 'http://example*', domain: false, tld_extra: false }], get_applies_tos(css)
  end

  test 'applies to single regexp' do
    css = <<~CSS
      @-moz-document regexp(".*example.*") {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: '.*example.*', domain: false, tld_extra: false }], get_applies_tos(css)
  end

  test 'multiple values in a rule' do
    css = <<~CSS
      @-moz-document domain(example.com), domain(example2.com) {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }, { text: 'example2.com', domain: true, tld_extra: false }], get_applies_tos(css)
  end

  test 'multiple document blocks' do
    css = <<~CSS
      @-moz-document domain(example.com) {
        a { color: red; }
      }
      @-moz-document domain(example2.com) {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }, { text: 'example2.com', domain: true, tld_extra: false }], get_applies_tos(css)
  end

  test 'parse_doc_blocks - one block' do
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

    blocks = CssParser.parse_doc_blocks(css)
    assert_equal 2, blocks.count
    first_block_css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL   http://example.net
      ==/UserStyle== */

    CSS
    assert_equal first_block_css, css[blocks[0].start_pos..blocks[0].end_pos]
    assert_empty blocks[0].matches

    second_block_css = <<-CSS

  a {
    color: red;
  }
    CSS
    assert_equal second_block_css, css[blocks[1].start_pos..blocks[1].end_pos]
    assert_equal 1, blocks[1].matches.count
  end

  test 'parse_doc_blocks - multiple blocks' do
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

      b { color: blue; }

      @-moz-document domain("example.net") {
        s {
          color: yellow;
        }
      }
    CSS

    blocks = CssParser.parse_doc_blocks(css)
    assert_equal 4, blocks.count
    first_block_css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL   http://example.net
      ==/UserStyle== */

    CSS
    assert_equal first_block_css, css[blocks[0].start_pos..blocks[0].end_pos]
    assert_empty blocks[0].matches

    second_block_css = <<-CSS

  a {
    color: red;
  }
    CSS
    assert_equal second_block_css, css[blocks[1].start_pos..blocks[1].end_pos]
    assert_equal 1, blocks[1].matches.count

    third_block_css = <<~CSS


      b { color: blue; }

    CSS
    assert_equal third_block_css, css[blocks[2].start_pos..blocks[2].end_pos]
    assert_empty blocks[2].matches

    fourth_block_css = <<-CSS

  s {
    color: yellow;
  }
    CSS
    assert_equal fourth_block_css, css[blocks[3].start_pos..blocks[3].end_pos]
    assert_equal 1, blocks[3].matches.count
  end

  test 'parse_doc_blocks - whitespace deficient' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL   http://example.net
      ==/UserStyle== */@-moz-document domain("example.com"){a{color:red;}}b{color:blue;}@-moz-document domain("example.net"){s{color:yellow;}}
    CSS

    blocks = CssParser.parse_doc_blocks(css)
    assert_equal 4, blocks.count
    first_block_css = <<~CSS.strip
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL   http://example.net
      ==/UserStyle== */
    CSS
    assert_equal first_block_css, css[blocks[0].start_pos..blocks[0].end_pos]
    assert_empty blocks[0].matches

    second_block_css = 'a{color:red;}'
    assert_equal second_block_css, css[blocks[1].start_pos..blocks[1].end_pos]
    assert_equal 1, blocks[1].matches.count

    third_block_css = 'b{color:blue;}'
    assert_equal third_block_css, css[blocks[2].start_pos..blocks[2].end_pos]
    assert_empty blocks[2].matches

    fourth_block_css = 's{color:yellow;}'
    assert_equal fourth_block_css, css[blocks[3].start_pos..blocks[3].end_pos]
    assert_equal 1, blocks[1].matches.count
  end

  test 'url-prefix with var' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @updateURL   http://example.net
      @var         text ip 'router ip' 192.168.1.1
      ==/UserStyle== */

      @-moz-document url-prefix(http:///*[[ip]]*//) {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: 'http:///*[[ip]]*//*', domain: false, tld_extra: false }], get_applies_tos(css)
  end

  test 'applies to invalid domain' do
    css = <<~CSS
      @-moz-document domain(/*[[yourDomain]]*/) {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: '/*[[yourDomain]]*/', domain: false, tld_extra: false }], get_applies_tos(css)
  end

  test '@document is equivalent to @-moz-document' do
    css = <<~CSS
      @document domain(example.com) {
        a { color: red; }
      }
    CSS
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_tos(css)
  end

  test 'empty @-moz-document' do
    css = <<~CSS
      @-moz-document domain(example.com) {

      }
      a { color: red; }
    CSS
    assert_empty get_applies_tos(css)
  end

  test 'unclosed @-moz-document' do
    css = <<~CSS
      @-moz-document url-prefix("https://www.example.com/") {
    CSS
    assert_empty get_applies_tos(css)
  end
end
