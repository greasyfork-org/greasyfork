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
      // @match *://*.example.com/*
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
        const styleNode = document.createElement("style");
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
      // @match *://*.example.com/*
      // @match *://*.example.net/*
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
        const styleNode = document.createElement("style");
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
      // @match *://*.example.com/*
      // @match *://*.example.net/*
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
        const styleNode = document.createElement("style");
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
      // @match *://*.example.com/*
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
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with ignoring global multiline comment' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      /* This is my global comment
         This is my second comment */
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
      // @match *://*.example.com/*
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
        const styleNode = document.createElement("style");
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
      // @match *://*.example.com/*
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
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with regexp' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document regexp("https?://www\\.google\\.com") {
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
      // @include /^(?:https?://www\\.google\\.com)$/
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
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion of multi blocked regexp' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document regexp("http://example\\.com/") {
        a {
          color: red;
        }
      }
      @-moz-document regexp("http://example\\.net/") {
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
      // @include /^(?:http://example\\.com/)$/
      // @include /^(?:http://example\\.net/)$/
      // ==/UserScript==

      (function() {
      let css = "";
      if (new RegExp("^(?:http://example\\\\.com/)\\$").test(location.href)) {
        css += `
          a {
            color: red;
          }
        `;
      }
      if (new RegExp("^(?:http://example\\\\.net/)\\$").test(location.href)) {
        css += `
          a {
            color: blue;
          }
        `;
      }
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        const styleNode = document.createElement("style");
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
    assert_equal %w[*://*.example.com/*], CssToJsConverter.calculate_matches_and_includes([block]).matches
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
    assert_no_error_reported do
      CssToJsConverter.convert(css)
    end
  end

  test 'js conversion of single blocked code with CSS @namespace' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @namespace url(http://www.w3.org/1999/xhtml);

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
      // @match *://*.example.com/*
      // ==/UserScript==

      (function() {
      let css = `@namespace url(http://www.w3.org/1999/xhtml);

        a {
          color: red;
        }
      `;
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion of single blocked code with CSS @charset and @namespace' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @charset "UTF-8";
      @namespace url(http://www.w3.org/1999/xhtml);

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
      // @match *://*.example.com/*
      // ==/UserScript==

      (function() {
      let css = `@charset "UTF-8";
      @namespace url(http://www.w3.org/1999/xhtml);

        a {
          color: red;
        }
      `;
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'global only' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      el { color: green; }


    CSS

    js = <<~JS
      // ==UserScript==
      // @name Example UserCSS style
      // @namespace github.com/openstyles/stylus
      // @version 1.0.0
      // @license unlicense
      // @grant GM_addStyle
      // @run-at document-start
      // @match *://*/*
      // ==/UserScript==

      (function() {
      let css = `el { color: green; }`;
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'global and site-specific with comments before each' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      /**/
      el { color: green; }

      /**/
      @-moz-document domain("facebook.com") { el { color: red; } }
    CSS

    js = <<~JS
      // ==UserScript==
      // @name Example UserCSS style
      // @namespace github.com/openstyles/stylus
      // @version 1.0.0
      // @license unlicense
      // @grant GM_addStyle
      // @run-at document-start
      // @match *://*/*
      // ==/UserScript==

      (function() {
      let css = "";
      css += `


      /**/
      el { color: green; }

      /**/
      `;
      if ((location.hostname === "facebook.com" || location.hostname.endsWith(".facebook.com"))) {
        css += ` el { color: red; } `;
      }
      if (typeof GM_addStyle !== "undefined") {
        GM_addStyle(css);
      } else {
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with url-prefix' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document url-prefix("https://www.example.com/") {
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
      // @match https://www.example.com/*
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
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with url-prefix at path' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document url-prefix("https://www.example.com/path") {
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
      // @match https://www.example.com/path*
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
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with url-prefix missing path slash' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document url-prefix("https://www.example.com") {
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
      // @include https://www.example.com*/*
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
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with url-prefix with port' do
    css = <<~CSS
      /* ==UserStyle==
      @name        Example UserCSS style
      @namespace   github.com/openstyles/stylus
      @version     1.0.0
      @license     unlicense
      ==/UserStyle== */

      @-moz-document url-prefix("https://www.example.com:8000/foo") {
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
      // @include https://www.example.com:8000/foo*
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
        const styleNode = document.createElement("style");
        styleNode.appendChild(document.createTextNode(css));
        (document.querySelector("head") || document.documentElement).appendChild(styleNode);
      }
      })();
    JS
    assert_equal js, CssToJsConverter.convert(css)
  end
end
