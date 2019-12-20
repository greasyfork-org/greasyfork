require 'test_helper'
require 'css_to_js_converter'
require 'css_parser'

class CssToJsConverterTest < ActiveSupport::TestCase
  test 'js conversion of single blocked code' do
    css = <<~END
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
    END

    js = <<~END
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
    END
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion of multi blocked code' do
    css = <<~END
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
    END

    js = <<~END
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
    END
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with multibyte characters' do
    css = <<~END
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
    END

    js = <<~END
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
    END
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with ignoring global comment' do
    css = <<~END
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
    END

    js = <<~END
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
    END
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'js conversion with escapy things' do
    css = <<~END
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
    END

    js = <<~END
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
    END
    assert_equal js, CssToJsConverter.convert(css)
  end

  test 'calculate_includes domain with overlapping URL' do
    block = CssParser::CssDocumentBlock.new([
                                                CssParser::CssDocumentMatch.new('domain', 'example.com'),
                                                CssParser::CssDocumentMatch.new('url', 'http://example.com/foo')
                                            ], nil, nil)
    assert_equal %w(http://example.com/* https://example.com/* http://*.example.com/* https://*.example.com/*), CssToJsConverter.calculate_includes([block])
  end

  test 'convertible default case' do
    css = <<~END
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
    END
    assert CssToJsConverter.convertible?(css)
  end

  test 'convertible with default preprocessor' do
    css = <<~END
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
    END
    assert CssToJsConverter.convertible?(css)
  end

  test 'not convertible with different preprocessor' do
    css = <<~END
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
    END
    assert !CssToJsConverter.convertible?(css)
  end

  test 'not convertible with var' do
    css = <<~END
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
    END
    assert !CssToJsConverter.convertible?(css)
  end
end