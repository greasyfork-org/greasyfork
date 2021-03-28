require 'test_helper'

class JsParserAppliesToTest < ActiveSupport::TestCase
  def get_applies_to(includes)
    js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n#{includes.map { |i| "// @include #{i}" }.join("\n")}\n// ==/UserScript==\nvar foo = \"bar\";"
    JsParser.calculate_applies_to_names(js)
  end

  test 'no includes' do
    assert_empty get_applies_to([])
  end

  test 'includes all' do
    assert_empty get_applies_to(['http://*'])
  end

  test 'includes all and specific' do
    assert_empty get_applies_to(['http://*', 'http://example.com/*'])
  end

  test 'includes all only protocol' do
    assert_empty get_applies_to(['http*'])
  end

  test 'one specific' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http://example.com/*'])
  end

  test 'two specific' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }, { text: 'anotherexample.com', domain: true, tld_extra: false }], get_applies_to(['http://example.com/*', 'http://anotherexample.com/*'])
  end

  test 'repeated specific' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http://example.com/*', 'http://example.com/*'])
  end

  test 'overlapping' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http://example.com/*', 'http://example.com/foo/*'])
  end

  test 'wildcard protocol' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['*://example.com/*'])
  end

  test 'wildcard protocol no colon' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['*//example.com/*'])
  end

  test 'invalid URL' do
    assert_equal [{ text: 'http://?what', domain: false, tld_extra: false }], get_applies_to(['http://?what'])
  end

  test 'URL with no host' do
    assert_equal [{ text: 'abc', domain: false, tld_extra: false }], get_applies_to(['abc'])
  end

  test 'http or https URL' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http*://example.com'])
  end

  test 'http or https URL skipping colon' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http*//example.com'])
  end

  test 'http or https URL skipping all puntucation' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http*example.com'])
  end

  test 'wildcard subdomain with dot' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http://*.example.com'])
  end

  test 'wildcard subdomain no dot' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http://*example.com'])
  end

  test 'wildcard subdomain and protocol' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['*example.com'])
  end

  test 'wildcard subdomain and protocol with dot' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['*.example.com'])
  end

  test 'wildcard subdomain and http or https' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http*.example.com'])
  end

  test 'wildcard subdomain without slashes' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http:*example.com'])
  end

  test '.tld' do
    names = get_applies_to(['http://example.tld'])
    assert_includes names, { text: 'example.com', domain: true, tld_extra: false }, names.inspect
  end

  test 'wildcard tld' do
    names = get_applies_to(['http://example.*'])
    assert_includes names, { text: 'example.com', domain: true, tld_extra: false }, names.inspect
  end

  test 'wildcard in ip' do
    names = get_applies_to(['http://1.2.3.*'])
    assert_includes names, { text: 'http://1.2.3.*', domain: false, tld_extra: false }, names.inspect
  end

  test 'wildcard before protocol' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['*http://example.com'])
  end

  test 'trailing dot on hostname' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['*http://example.com.'])
  end

  test 'multiple wildcards in host' do
    assert_equal [{ text: 'http://s*.*.example.*/*', domain: false, tld_extra: false }], get_applies_to(['http://s*.*.example.*/*'])
  end

  test 'subdomain' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['http://www.example.com/*'])
  end

  test 'tld' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }, { text: 'example.net', domain: true, tld_extra: true }, { text: 'example.org', domain: true, tld_extra: true }, { text: 'example.de', domain: true, tld_extra: true }, { text: 'example.co.uk', domain: true, tld_extra: true }], get_applies_to(['http://www.example.tld/*'])
  end

  test 'tld plus not tld' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }, { text: 'example.net', domain: true, tld_extra: true }, { text: 'example.de', domain: true, tld_extra: true }, { text: 'example.co.uk', domain: true, tld_extra: true }, { text: 'example.org', domain: true, tld_extra: false }], get_applies_to(['http://example.tld/*', 'http://example.org/*'])
  end

  test 'simple regexp' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/http://www\.example\.com/.+/'])
  end

  test 'regexp with escaped slashes' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/http:\/\/www\.example\.com\/.+/'])
  end

  test 'regexp with https?' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/https?://www\.example\.com/.+/'])
  end

  test 'regexp with https*' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/https*://www\.example\.com/.+/'])
  end

  test 'non-domain regexp?' do
    assert_equal [{ text: '/a/', domain: false, tld_extra: false }], get_applies_to(['/a/'])
  end

  test 'regexp with start of line' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/^http://www\.example\.com/.+/'])
  end

  test 'regexp with wildcard subdomain of line' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/http://.*example\.com/.+/'])
  end

  test 'regexp with escaped periods' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/^https://www\.example\.com/search/'])
  end

  test 'regexp with optional groups' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/http://(www\.)?example\.com//'])
  end

  test 'regexp non-optional path group' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }], get_applies_to(['/http:\/\/example\.com(\/|\/foo)/'])
  end

  test 'regexp non-optional domain group' do
    assert_equal [{ text: 'example.com', domain: true, tld_extra: false }, { text: 'sample.com', domain: true, tld_extra: false }], get_applies_to(['/(https?:\/\/)+(example|sample)(\.com)(\/.*)?/'])
  end

  test 'protocol match' do
    assert_equal [{ text: '/^(https?|ftp|unmht):.*/', domain: false, tld_extra: false }], get_applies_to(['/^(https?|ftp|unmht):.*/'])
  end

  test '0-min quantifier' do
    assert_equal [{ text: 'baidu.com', domain: true, tld_extra: false }], get_applies_to(['/^https?://tieba\\.baidu\\.com/((f\?kz=.*)|(p/.*))/'])
  end

  test 'look-ahead' do
    assert_equal [{ text: 'baidu.com', domain: true, tld_extra: false }], get_applies_to(['/^https?\:\/\/www\.baidu\.com\/(?=(s|baidu)\?|$)/'])
  end

  test 'character set' do
    assert_equal [{ text: 'baidu.com', domain: true, tld_extra: false }], get_applies_to(['/^https?\:\/\/www\.[bc]aidu\.com\//'])
  end

  test 'character range' do
    assert_equal [{ text: 'baidu.com', domain: true, tld_extra: false }], get_applies_to(['/^https?\:\/\/www\.[b-h]aidu\.com\//'])
  end

  test 'character type in character set' do
    assert_equal [{ text: 'aaidu.com', domain: true, tld_extra: false }], get_applies_to(['/^https?\:\/\/www\.[\w]aidu\.com\//'])
  end
end
