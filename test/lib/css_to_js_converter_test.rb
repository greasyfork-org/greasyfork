require 'test_helper'
require 'css_to_js_converter'
require 'css_parser'

class CssToJsConverterTest < ActiveSupport::TestCase
  test 'js conversion of single blocked code' do
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

    js = <<~JS
      // ==UserScript==
      // @name Example UserCSS style
      // @namespace github.com/openstyles/stylus
      // @version 1.0.0
      // @license unlicense
      // @grant GM_addStyle
      // @run-at document-start
      // @include http://example.com/*
      // @include https://example.com/*
      // @include http://*.example.com/*
      // @include https://*.example.com/*
      // ==/UserScript==

      (function() {
      let css = `
        a {
          color: red;
        }
      `;
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        let styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion of multi blocked code' do
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
      @-moz-document domain("example.net") {
        a {
          color: blue;
        }
      }
    CSS

    js = <<~JS
      // ==UserScript==
      // @name Example UserCSS style
      // @namespace github.com/openstyles/stylus
      // @version 1.0.0
      // @license unlicense
      // @grant GM_addStyle
      // @run-at document-start
      // @include http://example.com/*
      // @include https://example.com/*
      // @include http://*.example.com/*
      // @include https://*.example.com/*
      // @include http://example.net/*
      // @include https://example.net/*
      // @include http://*.example.net/*
      // @include https://*.example.net/*
      // ==/UserScript==

      (function() {
      let css = "";
      if ((location.hostname === "example.com" || location.hostname.endsWith(".example.com"))) {
        css += `
          a {
            color: red;
          }
        `;
      }
      if ((location.hostname === "example.net" || location.hostname.endsWith(".example.net"))) {
        css += `
          a {
            color: blue;
          }
        `;
      }
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        let styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with multibyte characters' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          content: "☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃";
        }
      }
      @-moz-document domain("example.net") {
        a {
          content: "☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃";
        }
      }
    CSS

    js = <<~JS
      // ==UserScript==
      // @name Example UserCSS style
      // @namespace github.com/openstyles/stylus
      // @version 1.0.0
      // @license unlicense
      // @grant GM_addStyle
      // @run-at document-start
      // @include http://example.com/*
      // @include https://example.com/*
      // @include http://*.example.com/*
      // @include https://*.example.com/*
      // @include http://example.net/*
      // @include https://example.net/*
      // @include http://*.example.net/*
      // @include https://*.example.net/*
      // ==/UserScript==

      (function() {
      let css = "";
      if ((location.hostname === "example.com" || location.hostname.endsWith(".example.com"))) {
        css += `
          a {
            content: "☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃";
          }
        `;
      }
      if ((location.hostname === "example.net" || location.hostname.endsWith(".example.net"))) {
        css += `
          a {
            content: "☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃☃";
          }
        `;
      }
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        let styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with ignoring global comment' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      /* This is my global comment */
      /* This is my second comment */
      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS

    js = <<~JS
      // ==UserScript==
      // @name Example UserCSS style
      // @namespace github.com/openstyles/stylus
      // @version 1.0.0
      // @license unlicense
      // @grant GM_addStyle
      // @run-at document-start
      // @include http://example.com/*
      // @include https://example.com/*
      // @include http://*.example.com/*
      // @include https://*.example.com/*
      // ==/UserScript==

      (function() {
      let css = `
        a {
          color: red;
        }
      `;
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        let styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with escapy things' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          content: "backtick : `";
          content: "backslash : \\";
        }
      }
    CSS

    js = <<~JS
      // ==UserScript==
      // @name Example UserCSS style
      // @namespace github.com/openstyles/stylus
      // @version 1.0.0
      // @license unlicense
      // @grant GM_addStyle
      // @run-at document-start
      // @include http://example.com/*
      // @include https://example.com/*
      // @include http://*.example.com/*
      // @include https://*.example.com/*
      // ==/UserScript==

      (function() {
      let css = `
        a {
          content: "backtick : \\`";
          content: "backslash : \\\\";
        }
      `;
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        let styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'calculate_includes domain with overlapping URL' do
    block = CssParser::CssDocumentBlock.new([
                                              CssParser::CssDocumentMatch.new('domain', 'example.com'),
                                              CssParser::CssDocumentMatch.new('url', 'http://example.com/foo'),
                                            ], nil, nil)
    assert_equal %w[http://example.com/* https://example.com/* http://*.example.com/* https://*.example.com/*], CssToJsConverter.calculate_includes([block])
  end

  test 'convertible default case' do
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
    assert CssToJsConverter.convertible?(css)
  end

  test 'convertible with default preprocessor' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @preprocessor default
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert CssToJsConverter.convertible?(css)
  end

  test 'not convertible with different preprocessor' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @preprocessor less
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_not CssToJsConverter.convertible?(css)
  end

  test 'not convertible with var' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      @var         something
      ==/UserStyle== */

      @-moz-document domain("example.com") {
        a {
          color: red;
        }
      }
    CSS
    assert_not CssToJsConverter.convertible?(css)
  end

  test 'unclosed -moz-doc' do
    css = <<~CSS
      /* ==UserStyle==
       @name Fanfou Refine
       @homepageURL T.B.D
       @description Fanfou Style
       @author shinemoon
       @namespace mooninsky
       @version 1.01
      ==/UserStyle== */
      @-moz-document domain("fanfou.com") {
          #container {
             width:960px!important;
             max-width:80%;
          }
          #stream li{
             font-family: FZYouHeiS 501L!important;
             font-size:12px!important;
             line-height:20px!important;
             width:80%!important;
          }
          .label {
             font-size:12px!important;
          }
          #goodapp, .sect {
             display:none;
          }
          #PopupUpdate textarea {
             font-family: FZYouHeiS 501L!important;
             font-size:12px!important;
             line-height:20px!important;
          }
    CSS
    CssToJsConverter.convert(css)
  end
end
